create_clock -period 8.000 -name sfp_mgt_clkp -waveform {0.000 4.000} [get_ports sfp_mgt_clkp]

# override complaints about MMCM not being in same clock tile as IOB
# we're really not fussed if it can't undo all the input delay
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets ref_clk_mmcm_inst/inst/clk_in_ref_clk_mmcm]
