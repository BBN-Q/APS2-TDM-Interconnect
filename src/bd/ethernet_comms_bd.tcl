
################################################################
# This is a generated script based on design: ethernet_comms_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source ethernet_comms_bd_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tfbg676-2
   set_property BOARD_PART bbn.com:aps2:fpga:0.1 [current_project]
}


# CHANGE DESIGN NAME HERE
set design_name ethernet_comms_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set sfp [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp ]
  set sfp_mgt_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sfp_mgt_clk ]
  set tcp_rx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 tcp_rx ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $tcp_rx
  set tcp_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 tcp_tx ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_TKEEP {0} \
CONFIG.HAS_TLAST {0} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.TDATA_NUM_BYTES {1} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $tcp_tx
  set udp_rx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 udp_rx ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $udp_rx
  set udp_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 udp_tx ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_TKEEP {0} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.TDATA_NUM_BYTES {1} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $udp_tx

  # Create ports
  set IPv4_addr [ create_bd_port -dir I -from 31 -to 0 IPv4_addr ]
  set clk_125MHz [ create_bd_port -dir I -type clk clk_125MHz ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_RESET {rst_comblock:tcp_rst:rst_eth_mac_logic} \
CONFIG.FREQ_HZ {125000000} \
 ] $clk_125MHz
  set clk_125MHz_mac [ create_bd_port -dir O -type clk clk_125MHz_mac ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_RESET {rst_eth_mac_rx_tx} \
 ] $clk_125MHz_mac
  set clk_ref_200MHz [ create_bd_port -dir I -type clk clk_ref_200MHz ]
  set gateway_ip_addr [ create_bd_port -dir I -from 31 -to 0 gateway_ip_addr ]
  set ifg_delay [ create_bd_port -dir I -from 7 -to 0 ifg_delay ]
  set mac_addr [ create_bd_port -dir I -from 47 -to 0 mac_addr ]
  set mgt_clk_locked [ create_bd_port -dir O mgt_clk_locked ]
  set pcs_pma_an_adv_config_vector [ create_bd_port -dir I -from 15 -to 0 pcs_pma_an_adv_config_vector ]
  set pcs_pma_an_restart_config [ create_bd_port -dir I pcs_pma_an_restart_config ]
  set pcs_pma_configuration_vector [ create_bd_port -dir I -from 4 -to 0 pcs_pma_configuration_vector ]
  set pcs_pma_status_vector [ create_bd_port -dir O -from 15 -to 0 pcs_pma_status_vector ]
  set rst_comblock [ create_bd_port -dir I -type rst rst_comblock ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_comblock
  set rst_eth_mac_logic [ create_bd_port -dir I -type rst rst_eth_mac_logic ]
  set rst_eth_mac_rx_tx [ create_bd_port -dir I -type rst rst_eth_mac_rx_tx ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_eth_mac_rx_tx
  set rst_pcs_pma [ create_bd_port -dir I -type rst rst_pcs_pma ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_pcs_pma
  set subnet_mask [ create_bd_port -dir I -from 31 -to 0 subnet_mask ]
  set tcp_port [ create_bd_port -dir I -from 15 -to 0 tcp_port ]
  set tcp_rst [ create_bd_port -dir I -type rst tcp_rst ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $tcp_rst
  set udp_rx_dest_port [ create_bd_port -dir I -from 15 -to 0 udp_rx_dest_port ]
  set udp_tx_dest_ip_addr [ create_bd_port -dir I -from 31 -to 0 udp_tx_dest_ip_addr ]
  set udp_tx_dest_port [ create_bd_port -dir I -from 15 -to 0 udp_tx_dest_port ]
  set udp_tx_src_port [ create_bd_port -dir I -from 15 -to 0 udp_tx_src_port ]

  # Create instance: ComBlocks5402_0, and set properties
  set ComBlocks5402_0 [ create_bd_cell -type ip -vlnv bbn.com:bbn:ComBlocks5402:1.0 ComBlocks5402_0 ]

  # Create instance: constant_0, and set properties
  set constant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $constant_0

  # Create instance: constant_1, and set properties
  set constant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1 ]

  # Create instance: eth_mac_1g_fifo_v1_0_0, and set properties
  set eth_mac_1g_fifo_v1_0_0 [ create_bd_cell -type ip -vlnv bbn.com:bbn:eth_mac_1g_fifo_v1_0:1.0 eth_mac_1g_fifo_v1_0_0 ]

  # Create instance: gig_ethernet_pcs_pma_0, and set properties
  set gig_ethernet_pcs_pma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma:15.2 gig_ethernet_pcs_pma_0 ]
  set_property -dict [ list \
CONFIG.Management_Interface {false} \
CONFIG.Physical_Interface {Transceiver} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Core} \
 ] $gig_ethernet_pcs_pma_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.Physical_Interface.VALUE_SRC {DEFAULT} \
 ] $gig_ethernet_pcs_pma_0

  # Create interface connections
  connect_bd_intf_net -intf_net ComBlocks5402_0_mac_tx [get_bd_intf_pins ComBlocks5402_0/mac_tx] [get_bd_intf_pins eth_mac_1g_fifo_v1_0_0/tx_axis]
  connect_bd_intf_net -intf_net ComBlocks5402_0_tcp_rx [get_bd_intf_ports tcp_rx] [get_bd_intf_pins ComBlocks5402_0/tcp_rx]
  connect_bd_intf_net -intf_net ComBlocks5402_0_udp_rx [get_bd_intf_ports udp_rx] [get_bd_intf_pins ComBlocks5402_0/udp_rx]
  connect_bd_intf_net -intf_net eth_mac_1g_fifo_v1_0_0_gmii [get_bd_intf_pins eth_mac_1g_fifo_v1_0_0/gmii] [get_bd_intf_pins gig_ethernet_pcs_pma_0/gmii_pcs_pma]
  connect_bd_intf_net -intf_net eth_mac_1g_fifo_v1_0_0_rx_axis [get_bd_intf_pins ComBlocks5402_0/mac_rx] [get_bd_intf_pins eth_mac_1g_fifo_v1_0_0/rx_axis]
  connect_bd_intf_net -intf_net gig_ethernet_pcs_pma_0_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins gig_ethernet_pcs_pma_0/sfp]
  connect_bd_intf_net -intf_net gtrefclk_in_1 [get_bd_intf_ports sfp_mgt_clk] [get_bd_intf_pins gig_ethernet_pcs_pma_0/gtrefclk_in]
  connect_bd_intf_net -intf_net tcp_tx_1 [get_bd_intf_ports tcp_tx] [get_bd_intf_pins ComBlocks5402_0/tcp_tx]
  connect_bd_intf_net -intf_net udp_tx_1 [get_bd_intf_ports udp_tx] [get_bd_intf_pins ComBlocks5402_0/udp_tx]

  # Create port connections
  connect_bd_net -net IPv4_addr_1 [get_bd_ports IPv4_addr] [get_bd_pins ComBlocks5402_0/IPv4_addr]
  connect_bd_net -net an_adv_config_vector_1 [get_bd_ports pcs_pma_an_adv_config_vector] [get_bd_pins gig_ethernet_pcs_pma_0/an_adv_config_vector]
  connect_bd_net -net an_restart_config_1 [get_bd_ports pcs_pma_an_restart_config] [get_bd_pins gig_ethernet_pcs_pma_0/an_restart_config]
  connect_bd_net -net configuration_vector_1 [get_bd_ports pcs_pma_configuration_vector] [get_bd_pins gig_ethernet_pcs_pma_0/configuration_vector]
  connect_bd_net -net constant_0_dout [get_bd_pins ComBlocks5402_0/dhcp_enable] [get_bd_pins constant_0/dout]
  connect_bd_net -net constant_1_dout [get_bd_pins constant_1/dout] [get_bd_pins gig_ethernet_pcs_pma_0/signal_detect]
  connect_bd_net -net gateway_ip_addr_1 [get_bd_ports gateway_ip_addr] [get_bd_pins ComBlocks5402_0/gateway_ip_addr]
  connect_bd_net -net gig_ethernet_pcs_pma_0_mmcm_locked_out [get_bd_ports mgt_clk_locked] [get_bd_pins gig_ethernet_pcs_pma_0/mmcm_locked_out]
  connect_bd_net -net gig_ethernet_pcs_pma_0_status_vector [get_bd_ports pcs_pma_status_vector] [get_bd_pins gig_ethernet_pcs_pma_0/status_vector]
  connect_bd_net -net gig_ethernet_pcs_pma_0_userclk2_out [get_bd_ports clk_125MHz_mac] [get_bd_pins eth_mac_1g_fifo_v1_0_0/rx_clk] [get_bd_pins eth_mac_1g_fifo_v1_0_0/tx_clk] [get_bd_pins gig_ethernet_pcs_pma_0/userclk2_out]
  connect_bd_net -net ifg_delay_1 [get_bd_ports ifg_delay] [get_bd_pins eth_mac_1g_fifo_v1_0_0/ifg_delay]
  connect_bd_net -net independent_clock_bufg_1 [get_bd_ports clk_ref_200MHz] [get_bd_pins gig_ethernet_pcs_pma_0/independent_clock_bufg]
  connect_bd_net -net logic_rst_1 [get_bd_ports rst_eth_mac_rx_tx] [get_bd_pins eth_mac_1g_fifo_v1_0_0/rx_rst] [get_bd_pins eth_mac_1g_fifo_v1_0_0/tx_rst]
  connect_bd_net -net logic_rst_2 [get_bd_ports rst_eth_mac_logic] [get_bd_pins eth_mac_1g_fifo_v1_0_0/logic_rst]
  connect_bd_net -net mac_addr_1 [get_bd_ports mac_addr] [get_bd_pins ComBlocks5402_0/mac_addr]
  connect_bd_net -net reset_1 [get_bd_ports rst_pcs_pma] [get_bd_pins gig_ethernet_pcs_pma_0/reset]
  connect_bd_net -net rst_1 [get_bd_ports rst_comblock] [get_bd_pins ComBlocks5402_0/rst]
  connect_bd_net -net rx_clk_1 [get_bd_ports clk_125MHz] [get_bd_pins ComBlocks5402_0/clk] [get_bd_pins eth_mac_1g_fifo_v1_0_0/logic_clk]
  connect_bd_net -net subnet_mask_1 [get_bd_ports subnet_mask] [get_bd_pins ComBlocks5402_0/subnet_mask]
  connect_bd_net -net tcp_port_1 [get_bd_ports tcp_port] [get_bd_pins ComBlocks5402_0/tcp_port]
  connect_bd_net -net tcp_rst_1 [get_bd_ports tcp_rst] [get_bd_pins ComBlocks5402_0/tcp_rst]
  connect_bd_net -net udp_rx_dest_port_1 [get_bd_ports udp_rx_dest_port] [get_bd_pins ComBlocks5402_0/udp_rx_dest_port]
  connect_bd_net -net udp_tx_dest_ip_addr_1 [get_bd_ports udp_tx_dest_ip_addr] [get_bd_pins ComBlocks5402_0/udp_tx_dest_ip_addr]
  connect_bd_net -net udp_tx_dest_port_1 [get_bd_ports udp_tx_dest_port] [get_bd_pins ComBlocks5402_0/udp_tx_dest_port]
  connect_bd_net -net udp_tx_src_port_1 [get_bd_ports udp_tx_src_port] [get_bd_pins ComBlocks5402_0/udp_tx_src_port]

  # Create address segments

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port sfp_mgt_clk -pg 1 -y 290 -defaultsOSRD
preplace port tcp_rx -pg 1 -y 750 -defaultsOSRD
preplace port clk_ref_200MHz -pg 1 -y 310 -defaultsOSRD
preplace port mgt_clk_locked -pg 1 -y 340 -defaultsOSRD
preplace port rst_eth_mac_logic -pg 1 -y 200 -defaultsOSRD
preplace port clk_125MHz -pg 1 -y 180 -defaultsOSRD
preplace port rst_eth_mac_rx_tx -pg 1 -y 120 -defaultsOSRD
preplace port udp_tx -pg 1 -y 640 -defaultsOSRD
preplace port clk_125MHz_mac -pg 1 -y 180 -defaultsOSRD
preplace port rst_pcs_pma -pg 1 -y 390 -defaultsOSRD
preplace port sfp -pg 1 -y 160 -defaultsOSRD
preplace port tcp_rst -pg 1 -y 720 -defaultsOSRD
preplace port pcs_pma_an_restart_config -pg 1 -y 370 -defaultsOSRD
preplace port udp_rx -pg 1 -y 730 -defaultsOSRD
preplace port tcp_tx -pg 1 -y 660 -defaultsOSRD
preplace port rst_comblock -pg 1 -y 700 -defaultsOSRD
preplace portBus udp_tx_src_port -pg 1 -y 870 -defaultsOSRD
preplace portBus udp_rx_dest_port -pg 1 -y 850 -defaultsOSRD
preplace portBus ifg_delay -pg 1 -y 220 -defaultsOSRD
preplace portBus mac_addr -pg 1 -y 740 -defaultsOSRD
preplace portBus gateway_ip_addr -pg 1 -y 800 -defaultsOSRD
preplace portBus pcs_pma_status_vector -pg 1 -y 400 -defaultsOSRD
preplace portBus tcp_port -pg 1 -y 930 -defaultsOSRD
preplace portBus udp_tx_dest_ip_addr -pg 1 -y 910 -defaultsOSRD
preplace portBus pcs_pma_an_adv_config_vector -pg 1 -y 350 -defaultsOSRD
preplace portBus pcs_pma_configuration_vector -pg 1 -y 330 -defaultsOSRD
preplace portBus subnet_mask -pg 1 -y 780 -defaultsOSRD
preplace portBus udp_tx_dest_port -pg 1 -y 890 -defaultsOSRD
preplace portBus IPv4_addr -pg 1 -y 760 -defaultsOSRD
preplace inst constant_0 -pg 1 -lvl 1 -y 820 -defaultsOSRD
preplace inst constant_1 -pg 1 -lvl 1 -y 440 -defaultsOSRD
preplace inst eth_mac_1g_fifo_v1_0_0 -pg 1 -lvl 1 -y 150 -defaultsOSRD
preplace inst gig_ethernet_pcs_pma_0 -pg 1 -lvl 2 -y 340 -defaultsOSRD
preplace inst ComBlocks5402_0 -pg 1 -lvl 2 -y 770 -defaultsOSRD
preplace netloc gig_ethernet_pcs_pma_0_sfp 1 2 1 NJ
preplace netloc eth_mac_1g_fifo_v1_0_0_gmii 1 1 1 330
preplace netloc udp_rx_dest_port_1 1 0 2 NJ 870 NJ
preplace netloc ifg_delay_1 1 0 1 NJ
preplace netloc ComBlocks5402_0_mac_tx 1 0 3 30 10 NJ 10 720
preplace netloc independent_clock_bufg_1 1 0 2 NJ 310 NJ
preplace netloc IPv4_addr_1 1 0 2 NJ 760 NJ
preplace netloc an_adv_config_vector_1 1 0 2 NJ 350 NJ
preplace netloc rst_1 1 0 2 NJ 700 NJ
preplace netloc ComBlocks5402_0_udp_rx 1 2 1 NJ
preplace netloc udp_tx_src_port_1 1 0 2 NJ 880 NJ
preplace netloc tcp_tx_1 1 0 2 NJ 660 NJ
preplace netloc mac_addr_1 1 0 2 NJ 740 NJ
preplace netloc configuration_vector_1 1 0 2 NJ 330 NJ
preplace netloc logic_rst_1 1 0 1 20
preplace netloc logic_rst_2 1 0 1 NJ
preplace netloc gig_ethernet_pcs_pma_0_userclk2_out 1 0 3 30 300 NJ 110 730
preplace netloc an_restart_config_1 1 0 2 NJ 370 NJ
preplace netloc udp_tx_dest_port_1 1 0 2 NJ 890 NJ
preplace netloc gtrefclk_in_1 1 0 2 NJ 290 NJ
preplace netloc tcp_rst_1 1 0 2 NJ 720 NJ
preplace netloc rx_clk_1 1 0 2 20 680 NJ
preplace netloc constant_1_dout 1 1 1 NJ
preplace netloc tcp_port_1 1 0 2 NJ 920 NJ
preplace netloc ComBlocks5402_0_tcp_rx 1 2 1 NJ
preplace netloc constant_0_dout 1 1 1 NJ
preplace netloc gig_ethernet_pcs_pma_0_mmcm_locked_out 1 2 1 NJ
preplace netloc subnet_mask_1 1 0 2 NJ 770 NJ
preplace netloc reset_1 1 0 2 NJ 390 NJ
preplace netloc gig_ethernet_pcs_pma_0_status_vector 1 2 1 NJ
preplace netloc gateway_ip_addr_1 1 0 2 NJ 730 NJ
preplace netloc udp_tx_1 1 0 2 NJ 640 NJ
preplace netloc eth_mac_1g_fifo_v1_0_0_rx_axis 1 1 1 340
preplace netloc udp_tx_dest_ip_addr_1 1 0 2 NJ 900 NJ
levelinfo -pg 1 0 180 530 750 -top 0 -bot 970
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


