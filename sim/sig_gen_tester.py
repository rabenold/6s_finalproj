import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join

# from cocotb_bus.bus import Bus
# from cocotb_bus.drivers import BusDriver
# from cocotb_bus.monitors import Monitor
# from cocotb_bus.monitors import BusMonitor
# import numpy as np


#pixel clk is 74.25 MHz
# half pd is then 1/2x   6.73 ns
async def generate_clock(clock_wire):
    while True: # repeat forever
        clock_wire.value = 0
        await Timer(1,units="ns")
        clock_wire.value = 1
        await Timer(1,units="ns")

async def reset(dut): 
    dut.rst_in.value = 1; 
    await ClockCycles(dut.pixel_clk_in,4)
    dut.rst_in.value = 0;


@cocotb.test()
async def test_one(dut):
    await cocotb.start(generate_clock(dut.pixel_clk_in))
    await reset(dut)
    await Timer(4000,units="ns")


def sig_gen_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "video_sig_gen.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="video_sig_gen",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="video_sig_gen",
        test_module="sig_gen_tester",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    print("STARTING TEST \n\n\n\n ===================================================")
    sig_gen_runner()
