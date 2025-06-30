# scripts/full_simulation.tcl

# 1) Open your existing project
open_project ./vivado_project/I2C_Master.xpr

# 2) Launch simulation in batch mode
#    -mode batch        : run without GUI
#    -tclbatch          : run your waveform commands
#    -debug typical     : include debug hooks for waveform/VCD
launch_simulation -mode batch work.i2c_master_tb \
  -debug typical \
  -tclbatch ../scripts/simulate.tcl

# 3) Exit Vivado
exit
