##################################################################
# Tcl script to create the TDM-interconnect HDL Vivado project for implementation on the APS2
#
# Usage: at the Tcl console manually set the argv to set the PROJECT_DIR and PROJECT_NAME and
# then source this file. E.g.
#
# set argv [list "/home/cryan/Programming/FPGA" "TDM-interconnect-impl"] or
# or  set argv [list "C:/Users/qlab/Documents/Xilinx Projects/" "TDM-interconnect-impl"]
# source create_impl_project.tcl
#
# from Vivado batch mode use the -tclargs to pass argv
# vivado -mode batch -source create_impl_project.tcl -tclargs "/home/cryan/Programming/FPGA" "TDM-interconnect-impl"
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

# setup project
create_project -force $PROJECT_NAME $PROJECT_DIR/$PROJECT_NAME -part xc7a200tfbg676-2
set_property "simulator_language" "Mixed" [current_project]
set_property "target_language" "VHDL" [current_project]

# Rebuild user ip_repo's index with our UserIP before adding any source files
# TODO: fix once APS2 comms is split out
set_property ip_repo_paths $REPO_PATH../APS2-HDL/src/ip [current_project]
update_ip_catalog -rebuild

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
set ip_srcs [glob $REPO_PATH/src/ip/xilinx/*.xci]
foreach xci $ip_srcs {
  import_ip $xci
}

#Sources
add_files -norecurse $REPO_PATH/src
add_files -norecurse $REPO_PATH/deps/VHDL-Components/src/Synchronizer.vhd
remove_files $REPO_PATH/src/APS2_interconnect_top.vhd

set_property top TDM_interconnect_top [current_fileset]
update_compile_order -fileset sources_1

# constraints
add_files -fileset constrs_1 -norecurse $REPO_PATH/deps/VHDL-Components/constraints/synchronizer.tcl
add_files -fileset constrs_1 -norecurse $REPO_PATH/constraints/pins_tdm.xdc
add_files -fileset constrs_1 -norecurse $REPO_PATH/constraints/timing_tdm.xdc
set_property target_constrs_file $REPO_PATH/constraints/timing_tdm.xdc [current_fileset -constrset]

#Enable headerless bit file output
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Manage the SATA PCS/PMA IP core ourselves so that we can muck with the HDL
# first generate HDL
export_ip_user_files -of_objects [get_files sata_interconnect_pcs_pma.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] sata_interconnect_pcs_pma.xci]
launch_run -jobs 4 sata_interconnect_pcs_pma_synth_1
wait_on_run sata_interconnect_pcs_pma_synth_1

# now take control
set_property IS_MANAGED false [get_files sata_interconnect_pcs_pma.xci]

# reset so that we don't reuse cached synthesis
reset_run sata_interconnect_pcs_pma_synth_1

# apply the patches

# on Windows look for Github git
if { $tcl_platform(platform) == "windows"} {
  set git_cmd [glob ~/AppData/Local/GitHub/PortableGit*/cmd/git.exe]
} else {
  set git_cmd git
}

set sata_interconnect_pcs_pma_ip_path [file dirname [get_files sata_interconnect_pcs_pma.xci]]
set cur_dir [pwd]
cd $sata_interconnect_pcs_pma_ip_path
exec $git_cmd apply -p6 --ignore-whitespace $REPO_PATH/src/ip/xilinx/sata_interconnect_pcs_pma.output_margins.patch
cd $cur_dir
