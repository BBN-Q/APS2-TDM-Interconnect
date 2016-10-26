##################################################################
# Tcl script to create the APS2-Interconnect HDL Vivado project for implementation on the APS2
#
# Usage: at the Tcl console manually set the argv to set the PROJECT_DIR and PROJECT_NAME and
# then source this file. E.g.
#
# set argv [list "/home/cryan/Programming/FPGA" "APS2-interconnect"] or
# or  set argv [list "C:/Users/qlab/Documents/Xilinx_Projects/" "APS2-interconnect"]
# source create_impl_project.tcl
#
# from Vivado batch mode use the -tclargs to pass argv
# vivado -mode batch -source create_impl_project.tcl -tclargs "/home/cryan/Programming/FPGA" "APS2-Interconnect-impl"
#
##################################################################

#parse arguments
set PROJECT_DIR [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set FIXED_IP [lindex $argv 2]

#Figure out the script path
set SCRIPT_PATH [file normalize [info script]]
set REPO_PATH [file dirname $SCRIPT_PATH]/../

# TODO: figure out how to handle board files
# set_param board.repoPaths [list $REPO_PATH../APS2-HDL/src/board_file]*/

# on Windows look for Github git
if { $tcl_platform(platform) == "windows"} {
  set git_cmd [glob ~/AppData/Local/GitHub/PortableGit*/cmd/git.exe]
} else {
  set git_cmd git
}

# setup project
create_project -force $PROJECT_NAME $PROJECT_DIR/$PROJECT_NAME -part xc7a200tfbg676-2
set_property "simulator_language" "Mixed" [current_project]
set_property "target_language" "VHDL" [current_project]

# Rebuild user ip_repo's index with our UserIP before adding any source files
# TODO: fix once APS2 comms is split out
set_property ip_repo_paths $REPO_PATH../APS2-HDL/src/ip [current_project]
update_ip_catalog -rebuild

# Add the relevant sources before constructing the block diagram
# helper script to add necessary files to current project

set APS2_COMMS_REPO_PATH $REPO_PATH/deps/APS2-Comms/

# create dependency outputs
set cur_dir [pwd]
cd $APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl
exec python axis_mux.py --ports=3 --output=axis_mux_3.v
exec python axis_arb_mux.py --ports=3 --output=axis_arb_mux_3.v
exec python axis_demux.py --ports=2 --output=axis_demux_2.v

# patch demux because select is keyword in VHDL
set fp [open axis_demux_2.v r]
set demux [read $fp]
close $fp
regsub -all {select} $demux control demux
set fp [open axis_demux_2.v w]
puts -nonewline $fp $demux
close $fp

#import into project and then delete to avoid dirty submodule
import_files -norecurse -flat \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_demux_2.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_mux_3.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_arb_mux_3.v

file delete axis_demux_2.v axis_mux_3.v axis_arb_mux_3.v

# patch the Com5402 module for UDP broadcast issue and add DHCP module
cd $APS2_COMMS_REPO_PATH/deps/ComBlock/5402
file copy -force com5402.vhd com5402.backup
# ignore whitespace warnings - seems a little dangerous
exec -ignorestderr $git_cmd apply com5402_dhcp.patch --directory=deps/ComBlock/5402 --ignore-whitespace
file copy -force com5402.backup com5402.vhd
cd $cur_dir

# BBN source files
add_files -norecurse $APS2_COMMS_REPO_PATH/src

# dependecies
add_files -norecurse $APS2_COMMS_REPO_PATH/deps/VHDL-Components/src/Synchronizer.vhd

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_adapter.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_srl_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_async_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_frame_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_async_frame_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/arbiter.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/priority_encoder.v

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_rx.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_tx.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/lfsr.v

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/arp_cache2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/arp.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/bram_dp2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/com5402_dhcp.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/com5402pkg.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/dhcp_client.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/igmp_query.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/igmp_report.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/packet_parsing.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/ping.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_rxbufndemux2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_server.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_txbuf.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_tx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/timer_4us.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/udp_rx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/udp_tx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/whois2.vhd

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

#Sources
add_files -norecurse $REPO_PATH/src
add_files -norecurse $REPO_PATH/deps/VHDL-Components/src/Synchronizer.vhd
add_files -norecurse $REPO_PATH/deps/APS2-Comms/src/eth_mac_1g_fifo_wrapper.vhd
add_files -norecurse $REPO_PATH/deps/APS2-Comms/src/com5402_wrapper.vhd
add_files -norecurse $REPO_PATH/deps/APS2-Comms/src/com5402_wrapper_pkg.vhd
add_files -fileset sources_1 -norecurse $REPO_PATH/deps/verilog-axis/rtl/axis_async_fifo.v
remove_files $REPO_PATH/src/TDM_interconnect_top.vhd

# Additional constraints
add_files -fileset constrs_1 -norecurse $APS2_COMMS_REPO_PATH/constraints/async_fifos.tcl

# Block designs
set bds [glob $REPO_PATH/src/bd/*.tcl]

foreach bd_path $bds {
  set bd [file rootname [file tail $bd_path]]
  puts "Working on $bd"
  source $REPO_PATH/src/bd/$bd.tcl -quiet
  regenerate_bd_layout
  validate_bd_design -quiet
	save_bd_design
  close_bd_design [get_bd_designs $bd]
  generate_target all [get_files $bd.bd] -quiet
  export_ip_user_files -of_objects [get_files $bd.bd] -no_script -force -quiet
}

#Xilinx IP
set xcix_srcs [glob $REPO_PATH/src/ip/xilinx/*.xcix]
add_files -norecurse $xcix_srcs
set xci_srcs [glob $REPO_PATH/src/ip/xilinx/*.xci]
import_ip $xci_srcs

set_property top APS2_interconnect_top [current_fileset]
update_compile_order -fileset sources_1

# constraints
add_files -fileset constrs_1 -norecurse $REPO_PATH/deps/VHDL-Components/constraints/synchronizer.tcl
add_files -fileset constrs_1 -norecurse $REPO_PATH/constraints/pins_aps2.xdc
add_files -fileset constrs_1 -norecurse $REPO_PATH/constraints/timing_aps2.xdc
reorder_files -fileset constrs_1 -after $REPO_PATH/constraints/timing_aps2.xdc $REPO_PATH/deps/APS2-Comms/constraints/async_fifos.tcl
set_property target_constrs_file $REPO_PATH/constraints/timing_aps2.xdc [current_fileset -constrset]

#Enable headerless bit file output
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Manage the SATA PCS/PMA IP core ourselves so that we can muck with the HDL
# first generate HDL
export_ip_user_files -of_objects [get_files sata_interconnect_pcs_pma.xci] -no_script -force -quiet
generate_target all [get_files sata_interconnect_pcs_pma.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] sata_interconnect_pcs_pma.xci]

# now take control
set_property IS_MANAGED false [get_files sata_interconnect_pcs_pma.xci]

# apply the patches
set sata_interconnect_pcs_pma_ip_path [file dirname [get_files sata_interconnect_pcs_pma.xci]]
set cur_dir [pwd]
cd $sata_interconnect_pcs_pma_ip_path
exec -ignorestderr $git_cmd apply -p6 --ignore-whitespace $REPO_PATH/src/ip/xilinx/sata_interconnect_pcs_pma.output_margins.patch $REPO_PATH/src/ip/xilinx/sata_interconnect_pcs_pma.300MHz_IDELAYCTRL.patch
cd $cur_dir
