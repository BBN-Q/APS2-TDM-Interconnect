-- Block level pieces of the SATA interconect
-- * lvds transceiver from Xilinx
-- * pcs/pma
--
-- modified from gig_ethernet_pcs_pma_0_block
--
-- Original author: Colm Ryan
-- Copyright 2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library gig_ethernet_pcs_pma_v15_2_0;
use gig_ethernet_pcs_pma_v15_2_0.all;

entity SATA_interconnect_block_level is
	port (
		rst : in std_logic;

		-- clocks
		clk125      : in std_logic;
		clk625      : in std_logic;
		clk208      : in std_logic;
		clk104      : in std_logic;
		clks_locked : in std_logic;

		--SATA tx/rx twisted pairs
		rx_p : in std_logic;
		rx_n : in std_logic;
		tx_p : in std_logic;
		tx_n : in std_logic;

		-- GMII Interface
		gmii_txd     : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
		gmii_tx_en   : in std_logic;                     -- Transmit control signal from client MAC.
		gmii_tx_er   : in std_logic;                     -- Transmit control signal from client MAC.
		gmii_rxd     : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
		gmii_rx_dv   : out std_logic;                    -- Received control signal to client MAC.
		gmii_rx_er   : out std_logic;                    -- Received control signal to client MAC.
		gmii_isolate : out std_logic;                    -- Tristate control to electrically isolate GMII.

		configuration_vector : in std_logic_vector(4 downto 0); -- Alternative to MDIO interface.
		an_interrupt         : out std_logic;                   -- Interrupt to processor to signal that Auto-Negotiation has completed
		an_adv_config_vector : in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
		an_restart_config    : in std_logic                      -- Alternate signal to modify AN restart bit in REG0

	);
end entity;

architecture arch of SATA_interconnect_block_level is

	signal rxchariscomma     : std_logic_vector (0 downto 0);    -- Comma detected in RXDATA.
	signal rxcharisk         : std_logic_vector (0 downto 0);    -- K character received (or extra data bit) in RXDATA.
	signal rxclkcorcnt       : std_logic_vector (2 downto 0);    -- Indicates clock correction.
	signal rxdata            : std_logic_vector (7 downto 0);    -- Data after 8B/10B decoding.
	signal rxdisperr         : std_logic_vector (0 downto 0);    -- Disparity-error in RXDATA.
	signal rxnotintable      : std_logic_vector (0 downto 0);    -- Non-existent 8B/10 code indicated.
	signal rxrundisp         : std_logic_vector (0 downto 0);    -- Running Disparity after current byte, becomes 9th data bit when RXNOTINTABLE='1'.

	signal txbuferr                   : std_logic;                                -- TX Buffer error (overflow or underflow).
	signal txchardispmode             : std_logic;                                -- Set running disparity for current byte.
	signal txchardispval              : std_logic;                                -- Set running disparity value.
	signal txcharisk                  : std_logic;                                -- K character transmitted in TXDATA.
	signal txdata                     : std_logic_vector(7 downto 0);             -- Data for 8B/10B encoding.
	signal enablealign                : std_logic;                                -- Allow the transceivers to serially realign to a comma character.
	signal lvds_phy_rdy_sig_det       : std_logic;
	signal mgt_tx_reset               : std_logic;
	signal mgt_rx_reset               : std_logic;
	signal mmcm_locked_sync_125 : std_logic;
	signal eye_mon_wait_time : std_logic_vector(11 downto 0);



begin


reset_wtd_timer : gig_ethernet_pcs_pma_0_reset_wtd_timer
	generic map ( WAIT_TIME	=> x"596825")
	port map (
		clk        =>	clk125m,
		data_valid =>	status_vector_int(1),
		reset      =>	wtd_reset
	);

rx_reset   <= wtd_reset or mgt_rx_reset;
phyaddress <= std_logic_vector(to_unsigned(1, phyaddress'length));

sgmii_clk_r <= sgmii_clk_r_i;

link_timer_value <= "0000000100" when EXAMPLE_SIMULATION =1 else "0000110010" ;

-- Eye Monitor Wait timer value is set to 12'03F for reducing simulation
-- time. The value is 12'FFF for normal runs
---------------------------------------------------------------------------
eye_mon_wait_time <= "111111111111" when (EXAMPLE_SIMULATION = 0) else	"000000111111";

sync_block_mmcm_locked : gig_ethernet_pcs_pma_0_sync_block
	port map (
		clk      => clk125m ,
		data_in  => mmcm_locked ,
		data_out => mmcm_locked_sync_125
	);


status_vector <= status_vector_int;

 -- Unused
 rxbufstatus(0) <= '0';
 lvds_phy_rdy_sig_det <= signal_detect and lvds_phy_ready;


 -----------------------------------------------------------------------------
 -- Instantiate the Xilinx encrypted PCS/PMA core
 -----------------------------------------------------------------------------

 gig_ethernet_pcs_pma_0_core : gig_ethernet_pcs_pma_v15_2_0
	 generic map (
		 C_ELABORATION_TRANSIENT_DIR => "BlankString",
		 C_COMPONENT_NAME            => "gig_ethernet_pcs_pma_0",
		 C_FAMILY                    => "artix7",
		 C_IS_SGMII                  => true,
		 C_USE_TRANSCEIVER           => false,
		 C_HAS_TEMAC                 => true,
		 C_USE_TBI                   => false,
		 C_USE_LVDS                  => true,
		 C_HAS_AN                    => true,
		 C_HAS_MDIO                  => false,
		 C_SGMII_PHY_MODE            => true,
		 C_DYNAMIC_SWITCHING         => false,
		 C_SGMII_FABRIC_BUFFER       => true
	 )
	 port map (
		 mgt_rx_reset         => mgt_rx_reset,
		 mgt_tx_reset         => mgt_tx_reset,
		 userclk              => clk125m,
		 userclk2             => clk125m,
		 dcm_locked           => mmcm_locked_sync_125,
		 rxbufstatus          => "00",
		 rxchariscomma        => rxchariscomma,
		 rxcharisk            => rxcharisk,
		 rxclkcorcnt          => rxclkcorcnt,
		 rxdata               => rxdata,
		 rxdisperr            => rxdisperr,
		 rxnotintable         => rxnotintable,
		 rxrundisp            => rxrundisp,
		 txbuferr             => txbuferr,
		 powerdown            => open,
		 txchardispmode       => txchardispmode,
		 txchardispval        => txchardispval,
		 txcharisk            => txcharisk,
		 txdata               => txdata,
		 enablealign          => enablealign,

		 gmii_txd             => gmii_txd_int,
		 gmii_tx_en           => gmii_tx_en_int,
		 gmii_tx_er           => gmii_tx_er_int,
		 gmii_rxd             => gmii_rxd_int,
		 gmii_rx_dv           => gmii_rx_dv_int,
		 gmii_rx_er           => gmii_rx_er_int,
		 gmii_isolate         => gmii_isolate,

		 mdc                  => '0',
		 mdio_in              => '0',
		 phyad                => (others => '0'),
		 configuration_valid  => '0',
		 mdio_out             => open,
		 mdio_tri             => open,
		 configuration_vector => configuration_vector,
		 an_interrupt         => an_interrupt,
		 an_adv_config_vector => an_adv_config_vector,
		 an_adv_config_val    => '0',
		 an_restart_config    => an_restart_config,
		 link_timer_value     => link_timer_value,
		 status_vector        => status_vector_int,
		 an_enable            => open,
		 speed_selection      => open,

		 reset                => reset,
		 signal_detect        => lvds_phy_rdy_sig_det,
		 -- drp interface used in 1588 mode
		 drp_dclk             => '0',
		 drp_gnt              => '0',
		 drp_drdy             => '0',
		 drp_do               => (others => '0'),
		 drp_req              => open,
		 drp_den              => open,
		 drp_dwe              => open,
		 drp_daddr            => open,
		 drp_di               => open,
		 -- 1588 Timer input
		 systemtimer_s_field  => (others => '0'),
		 systemtimer_ns_field => (others => '0'),
		 correction_timer     => (others => '0'),
		 rxphy_s_field          => open,
		 rxphy_ns_field         => open,
		 rxphy_correction_timer => open,

		 rxrecclk             => '0',
		 gtx_clk              => '0',
		 link_timer_basex     => (others => '0'),
		 link_timer_sgmii     => (others => '0'),
		 basex_or_sgmii       => '0',
		 rx_code_group0       => (others => '0'),
		 rx_code_group1       => (others => '0'),
		 pma_rx_clk0          => '0',
		 pma_rx_clk1          => '0',
		 tx_code_group        => open,
		 loc_ref              => open,
		 ewrap                => open,
		 en_cdet              => open,
		 reset_done           => '1'
	);

	-----------------------------------------------------------------------------
  --	instantiate the Xilinx LVDS transceiver wrapper
  -----------------------------------------------------------------------------

lvds_transceiver : entity work.gig_ethernet_pcs_pma_0_lvds_transceiver_k7
	port map (
		enmcommaalign    =>     enablealign,
		enpcommaalign    =>     enablealign,
		rxclkcorcnt      =>     rxclkcorcnt,
		txchardispmode   =>     txchardispmode,
		txchardispval    =>     txchardispval,
		txcharisk        =>     txcharisk,
		txdata           =>     txdata,
		txbuferr         =>     txbuferr,
		rxchariscomma    =>     rxchariscomma(0),
		rxcharisk        =>     rxcharisk(0),
		rxdata           =>     rxdata,
		rxdisperr        =>     rxdisperr(0),
		rxnotintable     =>     rxnotintable(0),
		rxrundisp        =>     rxrundisp(0),
		clk625           =>     clk625,
		clk208           =>     clk208,
		clk104           =>     clk104,
		phy_cdr_lock     =>     lvds_phy_ready,
		o_r_margin       =>     open,
		o_l_margin       =>     open,
		eye_mon_wait_time =>    eye_mon_wait_time,
		clk125           =>     clk125m,
		pin_sgmii_txn    =>     txn,
		pin_sgmii_txp    =>     txp,
		pin_sgmii_rxn    =>     rxn,
		pin_sgmii_rxp    =>     rxp,
		rxbuferr         =>     open,
		soft_tx_reset    =>     mgt_tx_reset,
		soft_rx_reset    =>     rx_reset,
		reset            =>     reset
	);


lvds_transceiver_wrapper : entity work.gig_ethernet_pcs_pma_0_lvds_transceiver_k7
 port map (
		enmcommaalign     => enablealign,
		enpcommaalign     => enablealign,
		rxclkcorcnt       => rxclkcorcnt,
		txchardispmode    => txchardispmode,
		txchardispval     => txchardispval,
		txcharisk         => txcharisk,
		txdata            => txdata,
		txbuferr          => txbuferr,
		rxchariscomma     => rxchariscomma(0),
		rxcharisk         => rxcharisk(0),
		rxdata            => rxdata,
		rxdisperr         => rxdisperr(0),
		rxnotintable      => rxnotintable(0),
		rxrundisp         => rxrundisp(0),
		clk625            => clk625,
		clk208            => clk208,
		clk104            => clk104,
		phy_cdr_lock      => lvds_phy_ready,
		o_r_margin        => open,
		o_l_margin        => open,
		eye_mon_wait_time => eye_mon_wait_time,
		clk125            => clk125,
		pin_sgmii_txn     => tx_n,
		pin_sgmii_txp     => tx_p,
		pin_sgmii_rxn     => rx_n,
		pin_sgmii_rxp     => rx_p,
		rxbuferr          => open,
		soft_tx_reset     => mgt_tx_reset,
		soft_rx_reset     => rx_reset,
		reset             => reset
	);





end architecture;
