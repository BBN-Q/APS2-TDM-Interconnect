create_clock -period 8.000 -name sfp_mgt_clkp -waveform {0.000 4.000} [get_ports sfp_mgt_clkp]

# override complaints about MMCM not being in same clock tile as IOB
# we're really not fussed if it can't undo all the input delay
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets ref_clk_mmcm_inst/inst/clk_in_ref_clk_mmcm]

# group SATA IDELAYCTRL and IDELAY because we run a non-standard 300MHz reference
set_property IODELAY_GROUP IO_DELAY_SATA [get_cells clocks_gen_inst/dlyctrl]
set_property IODELAY_GROUP IO_DELAY_SATA [get_cells -hierarchical -regexp -filter {PARENT =~ .*/lvds_transceiver_mw/gpio_sgmii_top_i/sgmii_phy_iob && REF_NAME == IDELAYE2}]

# Ignore false path in eth_mac_1g_fifo synchronizer
set_false_path -from [get_pins ethernet_comms_bd_inst/eth_mac_1g_fifo_v1_0_0/inst/rx_fifo/bad_frame_sync1_reg_reg/C] -to [get_pins ethernet_comms_bd_inst/eth_mac_1g_fifo_v1_0_0/inst/rx_fifo/bad_frame_sync2_reg_reg/D]
set_property ASYNC_REG TRUE [get_cells -regexp {ethernet_comms_bd_inst/eth_mac_1g_fifo_v1_0_0/inst/rx_fifo/bad_frame_sync[\d]_reg_reg}]
set_max_delay -datapath_only -from [get_cells ethernet_comms_bd_inst/eth_mac_1g_fifo_v1_0_0/inst/rx_fifo/bad_frame_sync1_reg_reg] -to [get_cells ethernet_comms_bd_inst/eth_mac_1g_fifo_v1_0_0/inst/rx_fifo/bad_frame_sync2_reg_reg] 2.0
