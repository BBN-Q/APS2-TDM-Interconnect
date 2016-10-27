-- Original author: Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SATA_interconnect_tb is
end;

architecture bench of SATA_interconnect_tb is

signal rst_tdm, rst_aps2 : std_logic := '0';
signal twisted_pair_a_p  : std_logic := '0';
signal twisted_pair_a_n  : std_logic := '0';
signal twisted_pair_b_p  : std_logic := '0';
signal twisted_pair_b_n  : std_logic := '0';

signal rx_tdata_aps2 : std_logic_vector(7 downto 0) := (others => '0');
signal rx_tvalid_aps2 : std_logic := '0';
signal rx_tready_aps2 : std_logic := '1';
signal tx_tdata_aps2 : std_logic_vector(7 downto 0) := (others => '0');
signal tx_tvalid_aps2 : std_logic := '0';
signal tx_tready_aps2 : std_logic := '0';

signal rx_tdata_tdm : std_logic_vector(7 downto 0) := (others => '0');
signal rx_tvalid_tdm : std_logic := '0';
signal rx_tready_tdm : std_logic := '1';
signal tx_tdata_tdm : std_logic_vector(7 downto 0) := (others => '0');
signal tx_tvalid_tdm : std_logic := '0';
signal tx_tready_tdm : std_logic := '0';

signal clk_user_aps2, clk_user_tdm : std_logic := '0';
signal clk125_ref_aps2, clk125_ref_tdm : std_logic := '0';
signal clk_625_sata, clk_208_sata, clk_104_sata, clk_125_sata : std_logic := '0';
signal sata_mmcm_locked : std_logic;

constant CLK_125MHZ_PERIOD : time := 10 ns;
constant CLK_300MHZ_PERIOD : time := 3.333333 ns;

signal link_established_aps2 : std_logic;
signal link_established_tdm : std_logic;
signal status_vector_aps2, status_vector_tdm : std_logic_vector(15 downto 0);

signal left_margin_aps2, right_margin_aps2, left_margin_tdm, right_margin_tdm :
	std_logic_vector(4 downto 0);

begin

	clk125_ref_aps2 <= not clk125_ref_aps2 after CLK_125MHZ_PERIOD / 2;
	clk125_ref_tdm <= not clk125_ref_tdm after CLK_125MHZ_PERIOD / 2;
	clk_user_aps2 <= not clk_user_aps2 after CLK_300MHZ_PERIOD / 2;
	clk_user_tdm <= clk_user_aps2;

	link_established_tdm <= status_vector_tdm(0);
	link_established_aps2 <= status_vector_aps2(0);

	sata_clocks_gen_inst : entity work.SATA_interconnect_clk_gen
		port map (
			rst        => rst_aps2,
			clk125_ref => clk125_ref_aps2,
			clk300     => clk_user_aps2,

			clk625 => clk_625_sata,
			clk208 => clk_208_sata,
			clk104 => clk_104_sata,
			clk125 => clk_125_sata,

			mmcm_locked => sata_mmcm_locked
		);

	aps2_uut : entity work.SATA_interconnect
		generic map ( EXAMPLE_SIMULATION => 1 )
		port map (
		rst        => rst_aps2,

		rx_p => twisted_pair_a_p,
		rx_n => twisted_pair_a_n,
		tx_p => twisted_pair_b_p,
		tx_n => twisted_pair_b_n,

		clk625   => clk_625_sata,
		clk208   => clk_208_sata,
		clk104   => clk_104_sata,
		clk125   => clk_125_sata,
		mmcm_locked => sata_mmcm_locked,

		status_vector => status_vector_aps2,
		left_margin   => left_margin_aps2,
		right_margin  => right_margin_aps2,

		clk_user  => clk_user_aps2,
		rx_tdata  => rx_tdata_aps2,
		rx_tvalid => rx_tvalid_aps2,
		rx_tready => rx_tready_aps2,
		tx_tdata  => tx_tdata_aps2,
		tx_tvalid => tx_tvalid_aps2,
		tx_tready => tx_tready_aps2
	);

	tdm_uut : entity work.SATA_interconnect
		generic map ( EXAMPLE_SIMULATION => 1 )
		port map (
		rst        => rst_tdm,

		rx_p   => twisted_pair_b_p,
		rx_n   => twisted_pair_b_n,
		tx_p   => twisted_pair_a_p,
		tx_n   => twisted_pair_a_n,

		clk625   => clk_625_sata,
		clk208   => clk_208_sata,
		clk104   => clk_104_sata,
		clk125   => clk_125_sata,
		mmcm_locked => sata_mmcm_locked,

		status_vector => status_vector_tdm,
		left_margin   => left_margin_tdm,
		right_margin  => right_margin_tdm,

		clk_user  => clk_user_tdm,
		rx_tdata  => rx_tdata_tdm,
		rx_tvalid => rx_tvalid_tdm,
		rx_tready => rx_tready_tdm,
		tx_tdata  => tx_tdata_tdm,
		tx_tvalid => tx_tvalid_tdm,
		tx_tready => tx_tready_tdm
	);


  stimulus: process
  begin

		rst_aps2 <= '1';
		rst_tdm <= '1';
		wait for 1 us;
		rst_tdm <= '0';
		wait for 10 us;
		rst_aps2 <= '0';

		wait until link_established_aps2 = '1' and link_established_tdm = '1';

		for ct in 1 to 4 loop
			wait until rising_edge(clk_user_tdm);
			tx_tdata_tdm <= std_logic_vector(to_unsigned(ct, 8));
			tx_tvalid_tdm <= '1';
		end loop;

		wait until rising_edge(clk_user_tdm);
		tx_tvalid_tdm <= '0';

		wait;

	end process;

end;
