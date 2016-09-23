-- Wrap the SATA interconnect from the APS2 side
-- On the APS2 wrapper we generate all necessary clocks with an MMCM
--
-- Original author: Graham Rowlands
-- Copyright 2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.verilog_axis_pkg.axis_async_fifo;

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

  signal mmcm_locked : std_logic := '0';

  signal sgmii_clk_r  : std_logic := '0';
  signal sgmii_clk_f  : std_logic := '0';
  signal sgmii_clk_en : std_logic := '0';

  type tx_framer_state_t is (IDLE, ADD_PREAMBLE, ADD_SFD, PASSTHROUGH);
  signal tx_framer_state : tx_framer_state_t := IDLE;
  type rx_framer_state_t is (IDLE, PASSTHROUGH);
  signal rx_framer_state : rx_framer_state_t := IDLE;

	signal tx_int_tdata : std_logic_vector(7 downto 0);
	signal tx_int_tvalid, tx_int_tready : std_logic := '0';
	signal rx_int_tvalid : std_logic := '0';

  begin

	reset_synchronizer_clk125 : entity work.synchronizer
	generic map(RESET_VALUE => '1', NUM_FLIP_FLOPS => 3)
	port map(rst => rst, clk => clk125, data_in => '0', data_out => rst_clk125);


	--------------------------------------------------------------------------------
	-- add preamble and start-of-frame to output going signals
	-- buffer input data in FIFO to cross clocks and
	--------------------------------------------------------------------------------

	tx_fifo : axis_async_fifo
	generic map (
		ADDR_WIDTH => 4,
		DATA_WIDTH => 8
	)
	port map (
		async_rst => rst,

		input_clk => clk_user,
		input_axis_tdata  => tx_tdata,
		input_axis_tvalid => tx_tvalid,
		input_axis_tready => tx_tready,
		input_axis_tlast  => '0',
		input_axis_tuser  => '0',

		output_clk => clk125,
		output_axis_tdata  => tx_int_tdata,
		output_axis_tvalid => tx_int_tvalid,
		output_axis_tready => tx_int_tready,
		output_axis_tlast  => open,
		output_axis_tuser  => open
	);

	-- add preamble 0x55 and SFD 0xD5 to outgoing tx data
	-- TODO: can we shortcircuit FIFO latency and start adding preamble early?
	tx_framer : process(clk125)
		constant PREAMBLE_LENGTH : natural := 2;
		variable preamble_ct : natural range 0 to PREAMBLE_LENGTH-1 := 0;
	begin
		if rising_edge(clk125) then

			if rst_clk125 = '1' then
				tx_framer_state <= IDLE;
				preamble_ct := 0;

			else
				case( tx_framer_state ) is

					when IDLE =>
						preamble_ct := 0;
						-- wait for new data to show up
						if tx_int_tvalid = '1' then
							tx_framer_state <= ADD_PREAMBLE;
						end if;

					when ADD_PREAMBLE =>
						if preamble_ct = PREAMBLE_LENGTH-1 then
							tx_framer_state <= ADD_SFD;
						else
							preamble_ct := preamble_ct + 1;
						end if;


					when ADD_SFD =>
						tx_framer_state <= PASSTHROUGH;

					when PASSTHROUGH =>
						if tx_int_tvalid = '0' then
							tx_framer_state <= IDLE;
						end if;

				end case;

			end if;
		end if;
	end process;

	with tx_framer_state select gmii_txd <=
		x"55" when ADD_PREAMBLE,
		x"D5" when ADD_SFD,
		tx_int_tdata when others;
	with tx_framer_state select gmii_tx_en <=
		'1' when ADD_PREAMBLE | ADD_SFD,
		tx_int_tvalid when PASSTHROUGH,
		'0' when IDLE;
	tx_int_tready <= '1' when tx_framer_state = PASSTHROUGH else '0';

	--------------------------------------------------------------------------------
	-- strip preamble and SFD from incoming rx packets and cross to user clock
	--------------------------------------------------------------------------------

	rx_deframer : process(clk125)
	begin
		if rising_edge(clk125) then

			if rst_clk125 = '1' then
				rx_framer_state <= IDLE;

			else
				case( rx_framer_state ) is

					when IDLE =>
						-- wait for SFD byte to show up
						if gmii_rx_dv = '1' and gmii_rxd = x"D5" then
							rx_framer_state <= PASSTHROUGH;
						end if;

					when PASSTHROUGH =>
						if gmii_rx_dv = '0' then
							rx_framer_state <= IDLE;
						end if;

				end case;

			end if;
		end if;
	end process;

	rx_int_tvalid <= gmii_rx_dv when rx_framer_state = PASSTHROUGH else '0';

	rx_fifo : axis_async_fifo
	generic map (
		ADDR_WIDTH => 4,
		DATA_WIDTH => 8
	)
	port map (
		async_rst => rst,

		input_clk => clk125,
		input_axis_tdata  => gmii_rxd,
		input_axis_tvalid => rx_int_tvalid,
		input_axis_tready => open,
		input_axis_tlast  => '0',
		input_axis_tuser  => '0',

		output_clk => clk_user,
		output_axis_tdata  => rx_tdata,
		output_axis_tvalid => rx_tvalid,
		output_axis_tready => rx_tready,
		output_axis_tlast  => open,
		output_axis_tuser  => open
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
