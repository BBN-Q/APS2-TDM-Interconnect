set_property PACKAGE_PIN M19 [get_ports fpga_resetl]
set_property IOSTANDARD LVCMOS25 [get_ports fpga_resetl]

set_property PACKAGE_PIN N21 [get_ports ref_clk]
set_property IOSTANDARD LVCMOS25 [get_ports ref_clk]

set_property PACKAGE_PIN A11 [get_ports sfp_rxn]
set_property PACKAGE_PIN B11 [get_ports sfp_rxp]
set_property PACKAGE_PIN A7 [get_ports sfp_txn]
set_property PACKAGE_PIN B7 [get_ports sfp_txp]

set_property PACKAGE_PIN F11 [get_ports sfp_mgt_clkp]
set_property PACKAGE_PIN E11 [get_ports sfp_mgt_clkn]

set_property PACKAGE_PIN M21 [get_ports cfg_clk]
set_property IOSTANDARD LVCMOS25 [get_ports cfg_clk]


#### SFP control ports ####

set_property PACKAGE_PIN U4 [get_ports sfp_enh]
set_property PACKAGE_PIN H2 [get_ports sfp_txdis]
set_property PACKAGE_PIN N4 [get_ports sfp_scl]
set_property PACKAGE_PIN M2 [get_ports sfp_los]
set_property PACKAGE_PIN L2 [get_ports sfp_presl]
set_property IOSTANDARD LVCMOS25 [get_ports -regexp sfp_(enh|txdis|scl|los|presl)]
set_property SLEW FAST [get_ports -regexp sfp_(enh|txdis|scl)]

#set_property PACKAGE_PIN P4 [get_ports sfp_sda]
#set_property IOSTANDARD LVCMOS25 [get_ports sfp_sda]
#set_property PACKAGE_PIN H1 [get_ports sfp_fault]
#set_property IOSTANDARD LVCMOS25 [get_ports sfp_fault]

#Set configuration voltages to avoid DRC issue
#Also set consistent IOSTANDARD for vp/vn from XADC which are hard-wired to Bank 0 which is used for config
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
#set_property IOSTANDARD LVCMOS25 [get_ports vp]
#set_property IOSTANDARD LVCMOS25 [get_ports vn]


#### Debug ####
set_property PACKAGE_PIN L23 [get_ports {dbg[0]}]
set_property PACKAGE_PIN P24 [get_ports {dbg[1]}]
set_property PACKAGE_PIN P23 [get_ports {dbg[2]}]
set_property PACKAGE_PIN M26 [get_ports {dbg[3]}]
set_property PACKAGE_PIN T25 [get_ports {dbg[4]}]
set_property PACKAGE_PIN T24 [get_ports {dbg[5]}]
set_property PACKAGE_PIN R23 [get_ports {dbg[6]}]
set_property PACKAGE_PIN T23 [get_ports {dbg[7]}]
set_property PACKAGE_PIN L24 [get_ports {dbg[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {dbg[*]}]
set_property SLEW FAST [get_ports {dbg[*]}]
set_property DRIVE 8 [get_ports -regexp {dbg\[[4-7]\]}]
set_property PULLUP true [get_ports {dbg[8]}]

# SATA
# Trigger Outputs
# TO1 = JT0
# TO2 = JT2
# TO3 = JT4
# TO4 = JT6
# TO5 = JC01
# TO6 = JT3
# TO7 = JT1
# TO8 = JT5
# TO9 = JT7
# TAUX = JT8

set_property PACKAGE_PIN A3   [get_ports {sata_clk_p[0]}]
set_property PACKAGE_PIN C2   [get_ports {sata_clk_p[1]}]
set_property PACKAGE_PIN E1   [get_ports {sata_clk_p[2]}]
set_property PACKAGE_PIN N3   [get_ports {sata_clk_p[3]}]
set_property PACKAGE_PIN R3   [get_ports {sata_clk_p[4]}]
set_property PACKAGE_PIN C26  [get_ports {sata_clk_p[5]}]
set_property PACKAGE_PIN B20  [get_ports {sata_clk_p[6]}]
set_property PACKAGE_PIN H26  [get_ports {sata_clk_p[7]}]
set_property PACKAGE_PIN AA24 [get_ports {sata_clk_p[8]}]

set_property PACKAGE_PIN C1   [get_ports {sata_dat_p[0]}]
set_property PACKAGE_PIN D3   [get_ports {sata_dat_p[1]}]
set_property PACKAGE_PIN G2   [get_ports {sata_dat_p[2]}]
set_property PACKAGE_PIN K1   [get_ports {sata_dat_p[3]}]
set_property PACKAGE_PIN R1   [get_ports {sata_dat_p[4]}]
set_property PACKAGE_PIN E26  [get_ports {sata_dat_p[5]}]
set_property PACKAGE_PIN A23  [get_ports {sata_dat_p[6]}]
set_property PACKAGE_PIN J25  [get_ports {sata_dat_p[7]}]
set_property PACKAGE_PIN AB24 [get_ports {sata_dat_p[8]}]

set_property IOSTANDARD LVDS_25 [get_ports {sata_clk_p[*]}]
set_property IOSTANDARD LVDS_25 [get_ports {sata_dat_p[*]}]

set_property DIFF_TERM true [get_ports {sata_dat_p[*]}]

# Auxiliary SATA
# set_property PACKAGE_PIN AD25 [get_ports {TRIG_CTRLP[0]}]
# set_property PACKAGE_PIN AE25 [get_ports {TRIG_CTRLP[1]}]

# set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLN[0]}]
# set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLN[1]}]
# set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLP[0]}]
# set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLP[1]}]

# set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLN[0]}]
# set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLN[1]}]
# set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLP[0]}]
# set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLP[1]}]
