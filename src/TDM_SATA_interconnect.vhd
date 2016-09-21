-- Wrap the SATA interconnect from the APS2 side
-- On the APS2 wrapper we generate all necessary clocks with an MMCM
--
-- Original author: Graham Rowlands
-- Copyright 2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.verilog_axis_TDMaxis_async_fifo;

entity TDM_SATA_interconnect is
	port (
		rst        : in std_logic;
		clk125_ref : in std_logic;
		clk300     : in std_logic;

		--SATA tx/rx twisted pairs
		rx_p      : in std_logic;
		rx_n      : in std_logic;
		tx_p      : out std_logic;
		tx_n      : out std_logic;

    --clocks from top level module
    --we share a global MMCM to conserve those resources
    clk625 : in std_logic;
    clk208 : in std_logic;
    clk104 : in std_logic;
    clk125 : in std_logic;

		--status
		status_vector    : out std_logic_vector(15 downto 0);
		left_margin      : out std_logic_vector(4 downto 0);
		right_margin     : out std_logic_vector(4 downto 0);

		--user data interface
		clk_user  : in std_logic;
		rx_tdata  : out std_logic_vector(7 downto 0);
		rx_tvalid : out std_logic;
		rx_tready : in std_logic;

		tx_tdata  : in std_logic_vector(7 downto 0);
		tx_tvalid : in std_logic;
		tx_tready : out std_logic
	);
end entity;

architecture arch of TDM_SATA_interconnect is

  signal rst_clk125 : std_logic;

  constant PCS_PMA_AN_ADV_CONFIG_VECTOR : std_logic_vector(15 downto 0) := x"0020"; --full-duplex see Table 2-55 (pg. 74) of PG047 November 18, 2015
  constant PCS_PMA_CONFIGURATION_VECTOR : std_logic_vector(4 downto 0) := b"10000"; --auto-negotiation enabled see Table 2-54

  signal gmii_txd   : std_logic_vector(7 downto 0) := (others => '0');
  signal gmii_tx_en : std_logic := '0';
  signal gmii_tx_er : std_logic := '0';
  signal gmii_rxd   : std_logic_vector(7 downto 0) := (others => '0');
  signal gmii_rx_dv : std_logic := '0';
  signal gmii_rx_er : std_logic := '0';

  signal mmcm_locked : std_logic_vector(8 downto 0) := (others => '0');

  signal sgmii_clk_r  : std_logic := '0';
  signal sgmii_clk_f  : std_logic := '0';
  signal sgmii_clk_en : std_logic := '0';

  -- State machine states
  type tx_framer_state_t is (IDLE, ADD_PREAMBLE, ADD_SFD, PASSTHROUGH);
  signal tx_framer_state : tx_framer_state_t := IDLE;
  type rx_framer_state_t is (IDLE, PASSTHROUGH);
  signal rx_framer_state : rx_framer_state_t := IDLE;

  type BYTE_ARRAY is array (0 to 8) of std_logic_vector(7 downto 0);
  signal tx_int_tdata : BYTE_ARRAY;
  signal tx_int_tvalid, tx_int_tready : std_logic_vector(8 downto 0) := (others => '0');
  signal rx_int_tvalid : std_logic_vector(8 downto 0) := (others => '0');

  begin

  -- instantiate the pcs/pma core
  pcs_pma_core_inst : entity work.sata_interconnect_pcs_pma
  	port map (
  		txn                  => tx_n,
  		txp                  => tx_p,
  		rxn                  => rx_n,
  		rxp                  => rx_p,
  		clk125m              => clk125,
  		mmcm_locked          => mmcm_locked,
  		sgmii_clk_r          => sgmii_clk_r,
  		sgmii_clk_f          => sgmii_clk_f,
  		sgmii_clk_en         => sgmii_clk_en,
  		clk625               => clk625,
  		clk208               => clk208,
  		clk104               => clk104,
  		gmii_txd             => gmii_txd,
  		gmii_tx_en           => gmii_tx_en,
  		gmii_tx_er           => gmii_tx_er,
  		gmii_rxd             => gmii_rxd,
  		gmii_rx_dv           => gmii_rx_dv,
  		gmii_rx_er           => gmii_rx_er,
  		gmii_isolate         => open,
  		configuration_vector => PCS_PMA_CONFIGURATION_VECTOR,
  		an_interrupt         => open,
  		an_adv_config_vector => PCS_PMA_AN_ADV_CONFIG_VECTOR,
  		an_restart_config    => '0',
  		speed_is_10_100      => '0',
  		speed_is_100         => '0',
  		status_vector        => status_vector,
  		reset                => rst,
  		signal_detect        => '1',
  		left_margin          => left_margin,
  		right_margin         => right_margin
  	);

  end architecture;
