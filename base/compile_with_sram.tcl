#/**************************************************/
#/* Compile Script for Synopsys Design Compiler     */
#/* Usage: dc_shell-t -f compile_with_sram.tcl     */
#/* OSU FreePDK 45nm + OpenRAM SRAM_32x64_1rw      */
#/**************************************************/

set my_verilog_files [list top_with_sram.sv controller.sv datapath.sv]
set my_toplevel top
set my_clock_pin clk

# Target 800 MHz (1.25 ns period)
set my_clk_freq_MHz 800
set my_input_delay_ns 0.05
set my_output_delay_ns 0.05

if { [info exists env(PDK_DIR)] } {
    set OSU_FREEPDK [format "%s%s" $env(PDK_DIR) "/osu_soc/lib/files"]
} else {
    set OSU_FREEPDK "/usr/local2/cadence/NCSU/SRC/FreePDK45/osu_soc/lib/files"
}

set search_path [list "." "./sram_32x64" "/usr/local2/COURSES/ADDV/LAB2/sram_32x64" $OSU_FREEPDK]
set alib_library_analysis_path $OSU_FREEPDK

set target_library [list gscl45nm.db SRAM_32x64_1rw.db]
set link_library [list * gscl45nm.db dw_foundation.sldb SRAM_32x64_1rw.db]

file delete -force ./WORK
define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"

analyze -format sverilog $my_verilog_files
elaborate $my_toplevel
current_design $my_toplevel

# 1. Link and uniquify before setting dont_touch on SRAM macro instances
link
uniquify

set_dont_touch [get_cells {imem/imem_ram dmem/dmem_ram}]

set my_period [expr 1000.0 / $my_clk_freq_MHz]

set find_clock [find port [list $my_clock_pin]]
if { $find_clock != [list] } {
   set clk_name $my_clock_pin
   create_clock -period $my_period $clk_name
} else {
   set clk_name vclk
   create_clock -period $my_period -name $clk_name
}

# 2. Apply input driver model only to non-clock data inputs
set data_inputs [remove_from_collection [all_inputs] [get_ports $my_clock_pin]]

set_driving_cell -lib_cell INVX1 $data_inputs
set_input_delay $my_input_delay_ns -clock $clk_name $data_inputs
set_output_delay $my_output_delay_ns -clock $clk_name [all_outputs]

set_fix_multiple_port_nets -all -buffer_constants

# 3. High effort mapping + design rule optimization
compile -ungroup_all -map_effort high
compile -incremental_mapping -only_design_rule

# Isolate SRAM address inputs to meet their 0.04 ns transition limit.
# These non-inverting buffers preserve logic; library limits are unchanged.
set addr_pins [get_pins -of_objects [get_cells {imem/imem_ram dmem/dmem_ram}] -filter "full_name =~ *addr0*"]
if {[sizeof_collection $addr_pins] != 12} {error "Expected 12 SRAM address pins"}
foreach_in_collection p $addr_pins {
    insert_buffer $p [get_lib_cells gscl45nm/BUFX2] -new_cell_names sram_addr_buf -new_net_names sram_addr_net
}

check_design

# 4. 6-digit precision reporting and saving synthesized DDC
redirect constraint.rep {
    report_constraint -all_violators -significant_digits 6
}
redirect timing.rep {
    report_timing -max_paths 5 -significant_digits 6
}
redirect cell.rep   { report_cell }
redirect power.rep  { report_power }
redirect area.rep   { report_area }

write -format verilog -hierarchy -output synthesized.v
write_sdc synthesized.sdc
write -format ddc -hierarchy -output synthesized.ddc

quit
