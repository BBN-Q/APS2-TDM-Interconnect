create_clock -period 8.000 -name sfp_mgt_clkp -waveform {0.000 4.000} [get_ports sfp_mgt_clkp]

# override complaints about MMCM not being in same clock tile as IOB
# we're really not fussed if it can't undo all the input delay
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets ref_clk_mmcm_inst/inst/clk_in_ref_clk_mmcm]

# group SATA IDELAYCTRL and IDELAY because we run a non-standard 300MHz reference
set_property IODELAY_GROUP IO_DELAY_SATA [get_cells SATA_interconnect_inst/clocks_gen_inst/dlyctrl]
set_property IODELAY_GROUP IO_DELAY_SATA [get_cells -hierarchical -regexp -filter {PARENT =~ .*/lvds_transceiver_mw/gpio_sgmii_top_i/sgmii_phy_iob && REF_NAME == IDELAYE2}]

# false path distributed RAM FIFOs
set_false_path -from [get_pins SATA_interconnect_inst/rx_fifo/mem_reg*/*/CLK] -to [get_pins SATA_interconnect_inst/rx_fifo/mem_read_data_reg_reg[*]/D]
set_false_path -from [get_pins SATA_interconnect_inst/tx_fifo/mem_reg*/*/CLK] -to [get_pins SATA_interconnect_inst/tx_fifo/mem_read_data_reg_reg[*]/D]
