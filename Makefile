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

.PHONY: bode_os sim_reg wave_reg sim_core wave_core sim_sys wave_sys clean

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

clean:
	rm -f $(TEST_DIR)/*.vvp
	rm -f *.vcd
	rm -f *.csv
	rm -f *.png
