
# Project name (folder will be vivado_project/)
set project_name "I2C_Master"
set part "xc7a35tcpg236-1"       ;# Replace with your FPGA part
set top_module "I2C_Master"      ;# Replace with your top-level HDL
set tb_top_module "i2c_master_tb"

# ==========================================

create_project $project_name ./vivado_project -part $part -force

# Add design sources
add_files src/rtl
add_files -fileset sim_1 src/sim

# Add constraints
# add_files -fileset constrs_1 constraints/*.xdc

# Set top module
set_property top $top_module [current_fileset]

# Set top-level testbench (change to match your testbench entity/module)
set_property top $tb_top_module [get_filesets sim_1]

# Set simulator
set_property target_simulator XSim [current_project]
update_compile_order -fileset sim_1
