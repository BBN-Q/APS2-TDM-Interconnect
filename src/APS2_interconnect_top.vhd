-- Wrap the SATA interconnect from the APS2 side
-- One the APS2 wrapper we generate all necessary with an MMCM
--
-- Original author: Colm Ryan
-- Copyright 2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity APS2_interconnect_top is
	port (
		rst        : in std_logic;
		clk125_ref : in std_logic;

		--SATA tx/rx twisted pairs
		rx_p      : in std_logic;
		rx_n      : in std_logic;
		tx_p      : out std_logic;
		tx_n      : out std_logic;

		--status
		link_established : out std_logic;

		--user data interface
		rx_tdata  : out std_logic_vector(7 downto 0);
		rx_tvalid : out std_logic;
		rx_last   : out std_logic;

		tx_tdata  : in std_logic_vector(7 downto 0);
		tx_tvalid : in std_logic;
		tx_last   : in std_logic

	);
end entity;

architecture arch of APS2_interconnect_top is

signal clk625, clk208, clk104, clk125 : std_logic := '0';

constant PCS_PMA_AN_ADV_CONFIG_VECTOR : std_logic_vector(15 downto 0) := x"0020"; --full-duplex see Table 2-55 (pg. 74) of PG047 November 18, 2015
constant PCS_PMA_CONFIGURATION_VECTOR : std_logic_vector(4 downto 0) := b"10000"; --auto-negotiation enabled see Table 2-54

signal status_vector : std_logic_vector(15 downto 0);

signal gmii_txd : std_logic_vector(7 downto 0) := (others => '0');
signal gmii_tx_en : std_logic := '0';
signal gmii_tx_er : std_logic := '0';
signal gmii_rxd : std_logic_vector(7 downto 0) := (others => '0');
signal gmii_rx_dv : std_logic := '0';
signal gmii_rx_er : std_logic := '0';

signal mmcm_locked : std_logic := '0';

signal sgmii_clk_r : std_logic := '0';
signal sgmii_clk_f : std_logic := '0';
signal sgmii_clk_en : std_logic := '0';

begin

link_established <= status_vector(0);

--generate all clocks from the reference 125MHz
clocks_gen_inst : entity work.gig_ethernet_pcs_pma_0_sgmii_phy_clk_gen
	port map (
		clk125_ref => clk125_ref,
		rst        => rst,

		o_clk625   => clk625,
		o_clk208   => clk208,
		o_clk104   => clk104,
		o_clk125   => clk125,

		o_mmcm_locked =>  mmcm_locked
	);


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
		gmii_txd             => tx_tdata,
		gmii_tx_en           => tx_tvalid,
		gmii_tx_er           => gmii_tx_er,
		gmii_rxd             => rx_tdata,
		gmii_rx_dv           => rx_tvalid,
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
		signal_detect        => '1'
	);


end architecture;