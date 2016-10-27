library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity APS2_interconnect_top is
	port (
	fpga_resetl : in	std_logic;	-- Global reset from config FPGA

	-- 10 MHz reference clock
	ref_clk : std_logic;

	-- 100 MHz CPLD clock
	cfg_clk : std_logic;

	-- SFP Tranceiver Interface
	sfp_mgt_clkp : in std_logic;		-- 125 MHz reference
	sfp_mgt_clkn : in std_logic;
	sfp_txp      : out std_logic;	 -- TX out to SFP
	sfp_txn      : out std_logic;
	sfp_rxp      : in std_logic;		-- RX in from SPF
	sfp_rxn      : in std_logic;

	-- SFP control signals
	sfp_enh   : buffer std_logic; -- sfp enable high
	sfp_scl   : out std_logic; -- sfp serial clock
	sfp_txdis : buffer std_logic; -- sfp disable laser
	-- sfp_sda		: in std_logic;	-- sfp serial data
	-- sfp_fault	: in std_logic;	-- sfp tx fault
	sfp_los   : in std_logic;	-- sfp loss of signal input laser power too low; also goes high when ethernet jack disconnected; low when plugged in
	sfp_presl : in std_logic;	-- sfp present low ??? doesn't seem to be in spec.

	-- SATA intefaces
	sata_clk_n  : in std_logic_vector(1 downto 0);
	sata_clk_p  : in std_logic_vector(1 downto 0);
	sata_data_n : out std_logic_vector(1 downto 0);
	sata_data_p : out std_logic_vector(1 downto 0);

	-- debug header
	dbg : inout std_logic_vector(8 downto 0)

  );
end entity;

architecture arch of APS2_interconnect_top is

	--- Constants ---
	constant IPV4_ADDR                    : std_logic_vector(31 downto 0) := x"c0a802c8"; -- 192.168.2.200
	constant MAC_ADDR                     : std_logic_vector(47 downto 0) := x"461ddb112233";
	constant SUBNET_MASK                  : std_logic_vector(31 downto 0) := x"ffffff00"; -- 255.255.255.0
	constant TCP_PORT                     : std_logic_vector(15 downto 0) := x"bb4e"; -- BBN
	constant UDP_PORT                     : std_logic_vector(15 downto 0) := x"bb4f"; -- BBN + 1
	constant GATEWAY_IP_ADDR              : std_logic_vector(31 downto 0) := x"c0a80201"; -- TODO: what this should be?
	constant PCS_PMA_AN_ADV_CONFIG_VECTOR : std_logic_vector(15 downto 0) := x"0020"; --full-duplex see Table 2-55 (pg. 74) of PG047 November 18, 2015
	constant PCS_PMA_CONFIGURATION_VECTOR : std_logic_vector(4 downto 0) := b"10000"; --auto-negotiation enabled see Table 2-54 (pg. 73) of PG047 November 18, 2015

	signal clk_125MHz_ref, clk_125MHz_data, clk_125MHz_mac, clk_200MHz, clk_300MHz : std_logic;
	signal ref_clk_locked, cfg_clk_locked : std_logic;

	signal rst_comblock, rst_eth_mac_rx_tx, rst_eth_mac_logic, rst_pcs_pma, rst_sata : std_logic := '0';
	signal rst_sync_clk125MHz_mac, rst_sync_clk125MHz_data : std_logic := '0';

	signal pcs_pma_status_vector : std_logic_vector(15 downto 0);
	signal pcs_pma_an_restart_config : std_logic := '0';
	signal mgt_clk_locked : std_logic;

	signal tcp_rx_tdata : std_logic_vector(7 downto 0) := (others => '0');
	signal tcp_rx_tvalid : std_logic := '0';
	signal tcp_rx_tready : std_logic := '1';
	signal tcp_tx_tdata : std_logic_vector(7 downto 0) := (others => '0');
	signal tcp_tx_tvalid, tcp_tx_tready : std_logic := '0';

	signal status_vector_sata : std_logic_vector(15 downto 0) := (others => '0');
	signal link_established_sata : std_logic;
	signal left_margin, right_margin : std_logic_vector(4 downto 0);

	attribute mark_debug : string;
	attribute mark_debug of tcp_rx_tdata : signal is "true";
	attribute mark_debug of tcp_rx_tvalid : signal is "true";
	attribute mark_debug of tcp_rx_tready : signal is "true";
	attribute mark_debug of tcp_tx_tdata : signal is "true";
	attribute mark_debug of tcp_tx_tvalid : signal is "true";
	attribute mark_debug of tcp_tx_tready : signal is "true";
	attribute mark_debug of left_margin : signal is "true";
	attribute mark_debug of right_margin : signal is "true";

begin

	-- Tie 125MHz data clock to reference clock
	clk_125MHz_data <= clk_125MHz_ref;

	ref_clk_mmcm_inst : entity work.ref_clk_mmcm
	port map (
		-- Clock in ports
		clk_in  => ref_clk,
		-- Clock out ports
		clk_125MHz_ref => clk_125MHz_ref,
		-- Status and control signals
		resetn     => fpga_resetl,
		locked     => ref_clk_locked
	);

  cfg_clk_mmcm_inst : entity work.cfg_clk_mmcm
	port map (
		-- Clock in ports
		clk_in  => cfg_clk,
		-- Clock out ports
		clk_200MHz => clk_200MHz,
		clk_300MHz => clk_300MHz,
		-- Status and control signals
		resetn     => fpga_resetl,
		locked     => cfg_clk_locked
	);

		--------------------  Resets  --------------------------
	--Disable SFP when not present
	SFP_ENH <= '0' when SFP_PRESL = '1' or FPGA_RESETL = '0' else '1';
	SFP_TXDIS <= '1' when SFP_PRESL = '1' or FPGA_RESETL = '0' else '0';

	-- SFP may take up to 300ms to initialize after power up according to spec.
	-- Chris used only 100ms
	-- wait that long and then reset the autonegotiation
	sfp_an_reset_proc : process( cfg_clk_locked, mgt_clk_locked, clk_125MHz_mac )
		variable reset_ct : unsigned(24 downto 0) := (others => '0');
	begin
		--Wait until all the clocks are locked
		if cfg_clk_locked = '0' or mgt_clk_locked = '0' then
			reset_ct := to_unsigned(12_500_000, reset_ct'length); --100ms at 125MHz ignoring off-by-one issues
			pcs_pma_an_restart_config <= '0';
		elsif rising_edge( clk_125MHz_mac ) then
			if reset_ct(reset_ct'high) = '1' then
				pcs_pma_an_restart_config <= '1';
			else
				reset_ct := reset_ct - 1;
			end if;
		end if;
	end process;

	--Wait until cfg_clk_locked so that we have 200MHz reference before deasserting pcs/pma reset
	rst_pcs_pma <= not cfg_clk_locked;

	--synchronize resets to appropriate clock domains
	reset_synchronizer_clk_125Mhz_mac : entity work.synchronizer
	generic map(RESET_VALUE => '1')
	port map(rst => rst_pcs_pma, clk => clk_125MHz_mac, data_in => '0', data_out => rst_sync_clk125MHz_mac);

	reset_synchronizer_clk_125Mhz_data : entity work.synchronizer
	generic map(RESET_VALUE => '1')
	port map(rst => rst_pcs_pma, clk => clk_125MHz_data, data_in => '0', data_out => rst_sync_clk125MHz_data);

	rst_eth_mac_rx_tx <= rst_sync_clk125MHz_mac;
	rst_eth_mac_logic <= rst_sync_clk125MHz_data;
	rst_comblock <= rst_sync_clk125MHz_data;

	rst_sata <= not (ref_clk_locked and cfg_clk_locked);

	dbg(7 downto 6) <= "01" when pcs_pma_status_vector(0) = '1' else "10";
	dbg(5 downto 4) <= "01" when link_established_sata = '1' else "10";
	dbg(3 downto 0) <= (others => '0');

	link_established_sata <= status_vector_sata(0);

	ethernet_comms_bd_inst : entity work.ethernet_comms_bd
		port map (
			--configuration constants
			IPv4_addr                    => IPV4_ADDR,
			mac_addr                     => MAC_ADDR,
			gateway_ip_addr              => GATEWAY_IP_ADDR,
			subnet_mask                  => SUBNET_MASK,
			tcp_port                     => TCP_PORT,
			pcs_pma_an_adv_config_vector => PCS_PMA_AN_ADV_CONFIG_VECTOR,
			pcs_pma_configuration_vector => PCS_PMA_CONFIGURATION_VECTOR,

			--clocks
			clk_125MHz        => clk_125MHz_data,
			clk_125MHz_mac    => clk_125MHz_mac,
			clk_ref_200MHz    => clk_200MHz,
			sfp_mgt_clk_clk_n => sfp_mgt_clkn,
			sfp_mgt_clk_clk_p => sfp_mgt_clkp,

			--resets
			rst_pcs_pma       => rst_pcs_pma,
			rst_eth_mac_rx_tx => rst_eth_mac_rx_tx,
			rst_eth_mac_logic => rst_eth_mac_logic,
			rst_comblock      => rst_comblock,
			tcp_rst           => rst_comblock,

			--SFP
			mgt_clk_locked            => mgt_clk_locked,
			pcs_pma_status_vector     => pcs_pma_status_vector,
			pcs_pma_an_restart_config => pcs_pma_an_restart_config,
			sfp_rxn                   => sfp_rxn,
			sfp_rxp                   => sfp_rxp,
			sfp_txn                   => sfp_txn,
			sfp_txp                   => sfp_txp,

			tcp_rx_tdata  => tcp_rx_tdata,
			tcp_rx_tready => tcp_rx_tready,
			tcp_rx_tvalid => tcp_rx_tvalid,

			tcp_tx_tdata  => tcp_tx_tdata,
			tcp_tx_tready => tcp_tx_tready,
			tcp_tx_tvalid => tcp_tx_tvalid

		);

	SATA_interconnect_inst : entity work.APS2_SATA_interconnect
		port map (
			rst => rst_sata,
			clk125_ref => clk_125MHz_ref,
			clk300     => clk_300MHz,

			rx_p => sata_clk_p(1),
			rx_n => sata_clk_n(1),
			tx_p => sata_data_p(1),
			tx_n => sata_data_n(1),

			status_vector => status_vector_sata,
			left_margin => left_margin,
			right_margin => right_margin,

			clk_user    => clk_125MHz_data,
			rx_tdata    => tcp_tx_tdata,
			rx_tvalid   => tcp_tx_tvalid,
			rx_tready   => tcp_tx_tready,
			tx_tdata    => tcp_rx_tdata,
			tx_tvalid   => tcp_rx_tvalid,
			tx_tready   => tcp_rx_tready
	);

	-- Avoid DRC error from not terminating sata_clk_p/n(0) and sata_data_p/n(0)
	sata_clk_0_buf: IBUFDS
	port map (
		O	=> open,
		I	=> sata_clk_p(0),
		IB => sata_clk_n(0)
	);

	sata_data_0_buf: OBUFDS
	port map (
		I	=> '0',
		O	=> sata_data_p(0),
		OB => sata_data_n(0)
	);

end architecture;
