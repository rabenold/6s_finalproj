import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
 

from cocotb_bus.bus import Bus
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import Monitor
from cocotb_bus.monitors import BusMonitor
import numpy as np

from PIL import Image 
import matplotlib.pyplot as plt
from skimage.color import ycbcr2rgb


async def generate_clock(clock_wire):
    while True: # repeat forever
        clock_wire.value = 0
        await Timer(5,units="ns")
        clock_wire.value = 1
        await Timer(5,units="ns")

async def reset(dut): 
    dut.rst_in.value = 1; 
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 0


@cocotb.test() 
async def test_one(dut):
    print("========= Starting Test =========")
    arr = []
    for i in range(256):
        arr.append(random.randint(0,65535))  #list of 16 bit ints 
    # arr done 
    assert(len(arr) == 256), "FUCK YOU"
    print("========= Array Generated =========")
    await cocotb.start(generate_clock(dut.clk_in))
    print("CLOCK GENERATEDfin")
    await reset(dut)
    print("STARTING SORT")
    while not dut.done.value:
        dut.freq_table_in.value = arr
        await ClockCycles(dut.clk_in,1)
    print(f"SORTED DONE with val = {dut.done.value}")
    sorted_arr = dut.sorted_table.value 
    print('=========7\n\n\n')
    # print(type(sorted_arr))
    # print(type(sorted_arr[0]))
    print(sorted_arr[:10])
    int_arr = [entry.integer for entry in sorted_arr]
    int_arr_sorted = sorted(int_arr)
    sorted_binary_arr = [bin(x)[2:].zfill(16) for x in int_arr_sorted]

    arr.sort()
    bin_arr = [bin(x)[2:] for x in arr]
    print(bin_arr[:10])
    # assert(bin_arr == sorted_binary_arr)


def brick_tester():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "brick_sort.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="bricksort",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="bricksort",
        test_module="brick_tester",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    brick_tester()