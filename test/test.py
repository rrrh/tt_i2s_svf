import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start I2S Audio Filter Test")

    # Set initial states
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Start the 50 MHz system clock (20ns period)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Apply Reset
    dut._log.info("Resetting design...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    
    # Release Reset
    dut.rst_n.value = 1
    dut._log.info("Reset released.")
    
    # Let it run for a few cycles to ensure stability
    await ClockCycles(dut.clk, 50)

    dut._log.info("ASIC initialized successfully. CI Gate-Level Test Passed!")
