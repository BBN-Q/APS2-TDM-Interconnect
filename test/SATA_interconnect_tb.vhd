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

signal rx_tdata : std_logic_vector(7 downto 0) := (others => '0');
signal rx_tvalid : std_logic := '0';
signal rx_last : std_logic := '0';
signal tx_tdata : std_logic_vector(7 downto 0) := (others => '0');
signal tx_tvalid : std_logic := '0';
signal tx_last : std_logic := '0';

signal clk125_aps2 : std_logic := '0';
signal clk125_tdm : std_logic := '0';

constant clk_period : time := 8 ns;

begin

	clk125_aps2 <= not clk125_aps2 after clk_period / 2;
	clk125_tdm <= not clk125_tdm after clk_period / 2;

	aps2_uut : entity work.APS2_interconnect_top
		port map (
		rst => rst,
		clk125_ref => clk125_aps2,
		rx_p => twisted_pair_a_p,
		rx_n => twisted_pair_a_n,
		tx_p => twisted_pair_b_p,
		tx_n => twisted_pair_b_n,
		rx_tdata => rx_tdata,
		rx_tvalid => rx_tvalid,
		rx_last => rx_last,
		tx_tdata => tx_tdata,
		tx_tvalid => tx_tvalid,
		tx_last => tx_last
	);

	tdm_uut : entity work.APS2_interconnect_top
		port map (
		rst => rst,
		clk125_ref => clk125_tdm,
		rx_p => twisted_pair_b_p,
		rx_n => twisted_pair_b_n,
		tx_p => twisted_pair_a_p,
		tx_n => twisted_pair_a_n,
		rx_tdata => rx_tdata,
		rx_tvalid => rx_tvalid,
		rx_last => rx_last,
		tx_tdata => tx_tdata,
		tx_tvalid => tx_tvalid,
		tx_last => tx_last
	);



  stimulus: process
  begin

		rst <= '1';
		wait for 1 us;
		rst <= '0';
		
		wait;

	end process;

end;
