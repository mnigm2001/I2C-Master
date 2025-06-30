# scripts/simulate.tcl

set tb_top_module "i2c_master_tb"

# ==========================================

# Launch simulation
xsim $tb_top_module -gui

# Or if you want non-GUI batch mode:
# xsim $tb_top_module

# Add waveform capture (if needed)
add_wave [get_objects *]
run all

# Save VCD
write_vcd ../waveforms/waveform.vcd

# Optional: Save a WDB if using Vivado's viewer
write_wave_database ../waveforms/waveform.wdb

exit
