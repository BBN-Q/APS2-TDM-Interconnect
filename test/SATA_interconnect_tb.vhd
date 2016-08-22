-- Original author: Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SATA_interconnect_tb is
end;

architecture bench of SATA_interconnect_tb is

signal rst : std_logic := '0';
signal twisted_pair_a_p : std_logic := '0';
signal twisted_pair_a_n : std_logic := '0';
signal twisted_pair_b_p : std_logic := '0';
signal twisted_pair_b_n : std_logic := '0';

signal rx_tdata_aps2 : std_logic_vector(7 downto 0) := (others => '0');
signal rx_tvalid_aps2 : std_logic := '0';
signal rx_tlast_aps2 : std_logic := '0';
signal tx_tdata_aps2 : std_logic_vector(7 downto 0) := (others => '0');
signal tx_tvalid_aps2 : std_logic := '0';
signal tx_tlast_aps2 : std_logic := '0';

signal rx_tdata_tdm : std_logic_vector(7 downto 0) := (others => '0');
signal rx_tvalid_tdm : std_logic := '0';
signal rx_tlast_tdm : std_logic := '0';
signal tx_tdata_tdm : std_logic_vector(7 downto 0) := (others => '0');
signal tx_tvalid_tdm : std_logic := '0';
signal tx_tlast_tdm : std_logic := '0';


signal clk125_aps2, clk125_tdm : std_logic := '0';
signal clk125_ref_aps2, clk125_ref_tdm : std_logic := '0';

constant clk_period : time := 8 ns;

signal link_established_aps2 : std_logic;
signal link_established_tdm : std_logic;

begin

	clk125_ref_aps2 <= not clk125_ref_aps2 after clk_period / 2;
	clk125_ref_tdm <= not clk125_ref_tdm after clk_period / 2;

	aps2_uut : entity work.APS2_SATA_interconnect
		port map (
		rst => rst,
		clk125_ref => clk125_ref_aps2,

		rx_p => twisted_pair_a_p,
		rx_n => twisted_pair_a_n,
		tx_p => twisted_pair_b_p,
		tx_n => twisted_pair_b_n,

		link_established => link_established_aps2,

		clk125_user => clk125_aps2,
		rx_tdata    => rx_tdata_aps2,
		rx_tvalid   => rx_tvalid_aps2,
		rx_tlast    => rx_tlast_aps2,
		tx_tdata    => tx_tdata_aps2,
		tx_tvalid   => tx_tvalid_aps2,
		tx_tlast    => tx_tlast_aps2
	);

	tdm_uut : entity work.APS2_SATA_interconnect
		port map (
		rst => rst,
		clk125_ref => clk125_ref_tdm,

		rx_p   => twisted_pair_b_p,
		rx_n   => twisted_pair_b_n,
		tx_p   => twisted_pair_a_p,
		tx_n   => twisted_pair_a_n,

		link_established => link_established_tdm,

		clk125_user => clk125_tdm,
		rx_tdata    => rx_tdata_tdm,
		rx_tvalid   => rx_tvalid_tdm,
		rx_tlast    => rx_tlast_tdm,
		tx_tdata    => tx_tdata_tdm,
		tx_tvalid   => tx_tvalid_tdm,
		tx_tlast    => tx_tlast_tdm
	);



  stimulus: process
  begin

		rst <= '1';
		wait for 1 us;
		rst <= '0';

		wait until link_established_aps2 = '1' and link_established_tdm = '1';


		for ct in 1 to 4 loop
			wait until rising_edge(clk125_tdm);
			tx_tdata_tdm <= std_logic_vector(to_unsigned(ct, 8));
			tx_tvalid_tdm <= '1';
		end loop;

		wait until rising_edge(clk125_tdm);
		tx_tvalid_tdm <= '0';

		wait;

	end process;

end;
