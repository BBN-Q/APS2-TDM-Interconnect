--------------------------------------------------------------------------------
-- Title      :
-- Project    : 1G/2.5G Ethernet PCS/PMA or SGMII LogiCORE
-- File       : gig_ethernet_pcs_pma_0_sgmii_phy_clk_gen.vhd
-- Author     : Xilinx
--------------------------------------------------------------------------------
-- (c) Copyright 2006 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

--
--
--------------------------------------------------------------------------------
-- Description:   This module takes in a 125 MHz clock from the MB and builds all the clocks
-- neccessary for GPIO-SGMII.
--------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;

library unisim;
use unisim.vcomponents.all;

entity gig_ethernet_pcs_pma_0_sgmii_phy_clk_gen is
port (
     clk125_ref : in std_logic;
     rst       : in std_logic;
     o_clk625  : out std_logic;
     o_clk208  : out std_logic;
     o_clk104  : out std_logic;
     o_clk125  : out std_logic;

     o_mmcm_locked : out std_logic
    );
end gig_ethernet_pcs_pma_0_sgmii_phy_clk_gen;

architecture xilinx of gig_ethernet_pcs_pma_0_sgmii_phy_clk_gen is

component gig_ethernet_pcs_pma_0_idelayctrl
  port(
       refclk                : in std_logic;
       rdy                   : out std_logic;
       rst                   : in std_logic
  );
end component;

 signal clk625_i : std_logic;
 signal clk125_i : std_logic;
 signal clk_fb   : std_logic;
 signal clk208_i : std_logic;
 signal clk104_i : std_logic;
 signal o_clk208_i  : std_logic;
 signal o_clk104_i : std_logic;
 signal clk_fb_i : std_logic;
 signal o_clk625_i : std_logic;
 signal o_clk125_i : std_logic;
 signal o_mmcm_locked_i : std_logic;
 signal mmcm_locked_inv : std_logic;
 signal idelayctrl_rdy_i : std_logic;
begin


sgmii_phy_mmcm_i : MMCME2_BASE
generic map(
      BANDWIDTH       => "HIGH",
      CLKFBOUT_MULT_F => 5.0,
      CLKIN1_PERIOD   => 8.0,
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_PHASE  => 0.0,
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE_F => 1.0,
      CLKOUT1_DIVIDE   => 3,
      CLKOUT2_DIVIDE   => 6,
      CLKOUT3_DIVIDE   => 5,
      CLKOUT4_DIVIDE   => 1,
      CLKOUT5_DIVIDE   => 1,
      CLKOUT6_DIVIDE   => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE      => 0.0,
      CLKOUT1_PHASE      => 0.0,
      CLKOUT2_PHASE      => 0.0,
      CLKOUT3_PHASE      => 0.0,
      CLKOUT4_PHASE      => 0.0,
      CLKOUT5_PHASE      => 0.0,
      CLKOUT6_PHASE      => 0.0,
      CLKOUT4_CASCADE    => FALSE,
      REF_JITTER1        => 0.0,
      STARTUP_WAIT       => FALSE
   )
   port map (
      CLKOUT0   => clk625_i,
      CLKOUT0B  => open,
      CLKOUT1   => clk208_i,
      CLKOUT1B  => open,
      CLKOUT2   => clk104_i,
      CLKOUT2B  => open,
      CLKOUT3   => clk125_i,
      CLKOUT3B  => open,
      CLKOUT4   => open,
      CLKOUT5   => open,
      CLKOUT6   => open,
      CLKFBOUT  => clk_fb_i,
      CLKFBOUTB => open,
      LOCKED    => o_mmcm_locked_i,
      CLKIN1    => clk125_ref,
      PWRDWN    => '0',
      RST       => rst,
      CLKFBIN   => clk_fb
   );

  -- Output buffering
  -------------------------------------
clkf_buf : BUFG
port map(
 O => clk_fb,
 I => clk_fb_i
);

clk625_buf : BUFG
port map (
 O => o_clk625_i,
 I => clk625_i
);

clk208_buf :BUFG
port map(
 O => o_clk208_i,
 I => clk208_i
);

clk104_buf : BUFG
port map(
 O => o_clk104_i,
 I => clk104_i
);


o_clk208 <= o_clk208_i;
o_clk104 <= o_clk104_i;

clk125_buf : BUFG
port map (
 O => o_clk125_i,
 I => clk125_i
);

o_clk625 <= o_clk625_i;
o_clk125 <= o_clk125_i;

o_mmcm_locked   <= o_mmcm_locked_i  and idelayctrl_rdy_i ;
mmcm_locked_inv <= not o_mmcm_locked_i;


-----------------------------------------------------------------------------
-- An IDELAYCTRL primitive needs to be instantiated for the Fixed Tap Delay
-- mode of the IDELAY.
-- All IDELAYs in Fixed Tap Delay mode and the IDELAYCTRL primitives have
-- to be LOC'ed in the XDC file.
-----------------------------------------------------------------------------


dlyctrl : IDELAYCTRL
generic map(
SIM_DEVICE => "7SERIES" )
port map(
   RDY       => idelayctrl_rdy_i,
   REFCLK    => o_clk208_i,
   RST       => mmcm_locked_inv
);

end xilinx;
