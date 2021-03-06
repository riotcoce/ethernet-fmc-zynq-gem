################################################################
# Block diagram build script
################################################################

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $design_name

current_bd_design $design_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Configure the PS: Enable GEM0, GEM1, GEM2 and GEM3
set_property -dict [list CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__ENET0__PERIPHERAL__IO {EMIO} \
CONFIG.PSU__ENET1__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__ENET1__PERIPHERAL__IO {EMIO} \
CONFIG.PSU__ENET2__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__ENET2__PERIPHERAL__IO {EMIO} \
CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__ENET3__PERIPHERAL__IO {EMIO} \
CONFIG.PSU__ENET0__GRP_MDIO__ENABLE {1} \
CONFIG.PSU__ENET0__GRP_MDIO__IO {EMIO} \
CONFIG.PSU__ENET1__GRP_MDIO__ENABLE {1} \
CONFIG.PSU__ENET1__GRP_MDIO__IO {EMIO} \
CONFIG.PSU__ENET2__GRP_MDIO__ENABLE {1} \
CONFIG.PSU__ENET2__GRP_MDIO__IO {EMIO} \
CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
CONFIG.PSU__ENET3__GRP_MDIO__IO {EMIO} \
CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__TTC0__PERIPHERAL__IO {EMIO}] [get_bd_cells zynq_ultra_ps_e_0]

# Connect the PL_CLK0 to the HPM0
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk]

# Add a processor system reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_zynq_ultra_ps_e_0_100M
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins rst_zynq_ultra_ps_e_0_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins rst_zynq_ultra_ps_e_0_100M/ext_reset_in]

# Add the GMII-to-RGMIIs
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_0
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_1
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_2
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_3
set_property -dict [list CONFIG.C_USE_IDELAY_CTRL {false}] [get_bd_cells gmii_to_rgmii_0]
set_property -dict [list CONFIG.C_USE_IDELAY_CTRL {false}] [get_bd_cells gmii_to_rgmii_1]
set_property -dict [list CONFIG.C_USE_IDELAY_CTRL {true} CONFIG.SupportLevel {Include_Shared_Logic_in_Core}] [get_bd_cells gmii_to_rgmii_2]
set_property -dict [list CONFIG.C_USE_IDELAY_CTRL {false}] [get_bd_cells gmii_to_rgmii_3]

# Connect GMII-to-RGMIIs to the GEMs
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/GMII_ENET0] [get_bd_intf_pins gmii_to_rgmii_0/GMII]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/MDIO_ENET0] [get_bd_intf_pins gmii_to_rgmii_0/MDIO_GEM]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/GMII_ENET1] [get_bd_intf_pins gmii_to_rgmii_1/GMII]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/MDIO_ENET1] [get_bd_intf_pins gmii_to_rgmii_1/MDIO_GEM]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/GMII_ENET2] [get_bd_intf_pins gmii_to_rgmii_2/GMII]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/MDIO_ENET2] [get_bd_intf_pins gmii_to_rgmii_2/MDIO_GEM]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/GMII_ENET3] [get_bd_intf_pins gmii_to_rgmii_3/GMII]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/MDIO_ENET3] [get_bd_intf_pins gmii_to_rgmii_3/MDIO_GEM]

# Connect the clocks
connect_bd_net [get_bd_pins gmii_to_rgmii_2/mmcm_locked_out] [get_bd_pins gmii_to_rgmii_0/mmcm_locked_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/ref_clk_out] [get_bd_pins gmii_to_rgmii_0/ref_clk_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_125m_out] [get_bd_pins gmii_to_rgmii_0/gmii_clk_125m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_25m_out] [get_bd_pins gmii_to_rgmii_0/gmii_clk_25m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_2_5m_out] [get_bd_pins gmii_to_rgmii_0/gmii_clk_2_5m_in]

connect_bd_net [get_bd_pins gmii_to_rgmii_2/mmcm_locked_out] [get_bd_pins gmii_to_rgmii_1/mmcm_locked_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/ref_clk_out] [get_bd_pins gmii_to_rgmii_1/ref_clk_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_125m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_125m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_25m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_25m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_2_5m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_2_5m_in]

connect_bd_net [get_bd_pins gmii_to_rgmii_2/mmcm_locked_out] [get_bd_pins gmii_to_rgmii_3/mmcm_locked_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/ref_clk_out] [get_bd_pins gmii_to_rgmii_3/ref_clk_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_125m_out] [get_bd_pins gmii_to_rgmii_3/gmii_clk_125m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_25m_out] [get_bd_pins gmii_to_rgmii_3/gmii_clk_25m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_2/gmii_clk_2_5m_out] [get_bd_pins gmii_to_rgmii_3/gmii_clk_2_5m_in]

# Make AXI Ethernet/GMII-to-RGMII ports external: MDIO, RGMII and RESET
# MDIO
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio_io_port_0
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_0/MDIO_PHY] [get_bd_intf_ports mdio_io_port_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio_io_port_1
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_1/MDIO_PHY] [get_bd_intf_ports mdio_io_port_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio_io_port_2
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_2/MDIO_PHY] [get_bd_intf_ports mdio_io_port_2]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio_io_port_3
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_3/MDIO_PHY] [get_bd_intf_ports mdio_io_port_3]
# RGMII
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_0
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_0/RGMII] [get_bd_intf_ports rgmii_port_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_1
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_1/RGMII] [get_bd_intf_ports rgmii_port_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_2
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_2/RGMII] [get_bd_intf_ports rgmii_port_2]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_3
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_3/RGMII] [get_bd_intf_ports rgmii_port_3]

# PHY RESET for GMII-to-RGMII ports 0, 1 and 2
create_bd_port -dir O reset_port_0
connect_bd_net [get_bd_pins /rst_zynq_ultra_ps_e_0_100M/peripheral_aresetn] [get_bd_ports reset_port_0]
create_bd_port -dir O reset_port_1
connect_bd_net [get_bd_pins /rst_zynq_ultra_ps_e_0_100M/peripheral_aresetn] [get_bd_ports reset_port_1]
create_bd_port -dir O reset_port_2
connect_bd_net [get_bd_pins /rst_zynq_ultra_ps_e_0_100M/peripheral_aresetn] [get_bd_ports reset_port_2]
create_bd_port -dir O reset_port_3
connect_bd_net [get_bd_pins /rst_zynq_ultra_ps_e_0_100M/peripheral_aresetn] [get_bd_ports reset_port_3]

# Connect GMII-to-RGMII resets
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_0/tx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_0/rx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_1/tx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_1/rx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_2/tx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_2/rx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_3/tx_reset]
connect_bd_net [get_bd_pins rst_zynq_ultra_ps_e_0_100M/peripheral_reset] [get_bd_pins gmii_to_rgmii_3/rx_reset]

# Create clock wizard for the 375MHz clock

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ.VALUE_SRC USER] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
CONFIG.PRIM_IN_FREQ {125} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {375} \
CONFIG.USE_LOCKED {false} \
CONFIG.USE_RESET {false} \
CONFIG.CLKIN1_JITTER_PS {80.0} \
CONFIG.MMCM_DIVCLK_DIVIDE {1} \
CONFIG.MMCM_CLKFBOUT_MULT_F {9.750} \
CONFIG.MMCM_CLKIN1_PERIOD {8.0} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.250} \
CONFIG.CLKOUT1_JITTER {86.562} \
CONFIG.CLKOUT1_PHASE_ERROR {84.521}] [get_bd_cells clk_wiz_0]

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins gmii_to_rgmii_2/clkin]

# Connect ports for the Ethernet FMC 125MHz clock
create_bd_port -dir I -from 0 -to 0 -type clk ref_clk_p
connect_bd_net [get_bd_pins /clk_wiz_0/clk_in1_p] [get_bd_ports ref_clk_p]
set_property CONFIG.FREQ_HZ 125000000 [get_bd_ports ref_clk_p]
create_bd_port -dir I -from 0 -to 0 -type clk ref_clk_n
connect_bd_net [get_bd_pins /clk_wiz_0/clk_in1_n] [get_bd_ports ref_clk_n]
set_property CONFIG.FREQ_HZ 125000000 [get_bd_ports ref_clk_n]

# Create IDELAYCTRL for the GMII-to-RGMII without shared logic
create_bd_cell -type ip -vlnv xilinx.com:ip:util_idelay_ctrl util_idelay_ctrl_0
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins util_idelay_ctrl_0/ref_clk]

# Processor System Reset for the IDELAYCTRL reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins util_idelay_ctrl_0/rst]
connect_bd_net [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

# Create Ethernet FMC reference clock output enable and frequency select

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ref_clk_oe
create_bd_port -dir O -from 0 -to 0 ref_clk_oe
connect_bd_net [get_bd_pins /ref_clk_oe/dout] [get_bd_ports ref_clk_oe]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ref_clk_fsel
create_bd_port -dir O -from 0 -to 0 ref_clk_fsel
connect_bd_net [get_bd_pins /ref_clk_fsel/dout] [get_bd_ports ref_clk_fsel]

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
