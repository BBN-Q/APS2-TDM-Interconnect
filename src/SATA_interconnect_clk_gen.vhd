-- Generate all the clocks needed for the SATA interconnect along with an
-- IDELAYCTRL for calibrating the IDELAYs
--
-- Original author: Colm Ryan
-- Copyright 2016 Raytheon BBN Technologieslibrary ieee;

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity SATA_interconnect_clk_gen is
	port (
		rst         : in std_logic;
		clk125_ref  : in std_logic;
		clk300      : in std_logic;

		clk625      : out std_logic;
		clk208      : out std_logic;
		clk104      : out std_logic;
		clk125      : out std_logic;
		mmcm_locked : out std_logic
	);
end entity;

architecture arch of SATA_interconnect_clk_gen is

signal mmcm_locked_int : std_logic;
signal clk208_int : std_logic;
signal idelayctrl_rdy : std_logic;

begin

mmcm_locked <= mmcm_locked_int and idelayctrl_rdy;
clk208 <= clk208_int;

sata_interconnect_mmcm_inst : entity work.sata_interconnect_mmcm
	port map (
		-- Clock in ports
		clk125_ref => clk125_ref,
		-- Clock out ports
		clk625 => clk625,
		clk208 => clk208_int,
		clk104 => clk104,
		clk125 => clk125,
		-- Status and control signals
		reset => rst,
		locked => mmcm_locked_int
	);


	dlyctrl : IDELAYCTRL
	generic map(
	SIM_DEVICE => "7SERIES" )
	port map(
	   RDY       => idelayctrl_rdy,
	   REFCLK    => clk300,
	   RST       => not mmcm_locked_int
	);


end architecture;
