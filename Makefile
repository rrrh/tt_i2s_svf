IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

SRC_DIR  = src
TEST_DIR = test

SRC_TOP    = $(SRC_DIR)/tt_um_audio_filter.v
SRC_CORE   = $(SRC_DIR)/audio_filter_core.v
SRC_SVF_OS = $(SRC_DIR)/svf_multiplierless_os.v
SRC_REG    = $(SRC_DIR)/spi_reg_bank.v
SRC_RX     = $(SRC_DIR)/i2s_rx.v
SRC_TX     = $(SRC_DIR)/i2s_tx.v

TB_BODE_OS = $(TEST_DIR)/tb_bode_os.v
OUT_BODE_OS= $(TEST_DIR)/tb_bode_os.vvp

TB_REG   = $(TEST_DIR)/tb_spi_reg_bank.v
OUT_REG  = $(TEST_DIR)/tb_spi_reg_bank.vvp
VCD_REG  = tb_spi_reg_bank.vcd

TB_CORE  = $(TEST_DIR)/tb_audio_filter_core.v
OUT_CORE = $(TEST_DIR)/tb_audio_filter_core.vvp
VCD_CORE = tb_audio_filter_core.vcd

TB_SYS   = $(TEST_DIR)/tb_system.v
OUT_SYS  = $(TEST_DIR)/tb_system.vvp
VCD_SYS  = tb_system.vcd

TB_SWEEP  = $(TEST_DIR)/tb_sine_sweep.v
OUT_SWEEP = $(TEST_DIR)/tb_sine_sweep.vvp

TB_I2S_FULL  = $(TEST_DIR)/tb_i2s_system_full.v
OUT_I2S_FULL = $(TEST_DIR)/tb_i2s_system_full.vvp
VCD_I2S_FULL = tb_i2s_system_full.vcd


.PHONY: bode_os sim_reg wave_reg sim_core wave_core sim_sys wave_sys i2s_full wave_i2s_full clean

.PHONY: clean
clean:
	rm -f test/*.vvp test/*.vcd *.vvp *.vcd *.csv *.png
	rm -rf sim_build/

i2s_full:
	@echo "Compiling End-to-End I2S physical testbench..."
	$(IVERILOG) -o $(OUT_I2S_FULL) -I $(SRC_DIR) $(TB_I2S_FULL) $(SRC_TOP) $(SRC_CORE) $(SRC_REG) $(SRC_SVF_OS) $(SRC_RX) $(SRC_TX)
	@echo "Running simulation..."
	$(VVP) $(OUT_I2S_FULL)
	@echo "Plotting physical output waveforms..."
	python3 $(TEST_DIR)/plot_i2s_system_full.py

wave_i2s_full: i2s_full
	$(GTKWAVE) $(VCD_I2S_FULL) &


sweep:
	$(IVERILOG) -o $(OUT_SWEEP) -I $(SRC_DIR) $(TB_SWEEP) $(SRC_CORE) $(SRC_REG) $(SRC_SVF_OS)
	$(VVP) $(OUT_SWEEP)
	python3 $(TEST_DIR)/plot_sine_sweep.py

bode_os:
	$(IVERILOG) -o $(OUT_BODE_OS) -I $(SRC_DIR) $(TB_BODE_OS) $(SRC_SVF_OS)
	$(VVP) $(OUT_BODE_OS)
	python3 $(TEST_DIR)/plot_bode_os.py

sim_reg:
	$(IVERILOG) -o $(OUT_REG) -I $(SRC_DIR) $(TB_REG) $(SRC_REG)
	$(VVP) $(OUT_REG)

wave_reg: sim_reg
	$(GTKWAVE) $(VCD_REG) &

sim_core:
	$(IVERILOG) -o $(OUT_CORE) -I $(SRC_DIR) $(TB_CORE) $(SRC_CORE) $(SRC_REG) $(SRC_SVF_OS)
	$(VVP) $(OUT_CORE)

wave_core: sim_core
	$(GTKWAVE) $(VCD_CORE) &

sim_sys:
	$(IVERILOG) -o $(OUT_SYS) -I $(SRC_DIR) $(TB_SYS) $(SRC_TOP) $(SRC_CORE) $(SRC_REG) $(SRC_SVF_OS) $(SRC_RX) $(SRC_TX)
	$(VVP) $(OUT_SYS)
	python3 $(TEST_DIR)/plot_system.py

wave_sys: sim_sys
	$(GTKWAVE) $(VCD_SYS) &

