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
 
import numpy as np

from PIL import Image 
import matplotlib.pyplot as plt


async def generate_clock(clock_wire):
    while True: # repeat forever
        clock_wire.value = 0
        await Timer(5,units="ns")
        clock_wire.value = 1
        await Timer(5,units="ns")
async def reset(dut):
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,1)

"""zig zagged in 
[ 1,  2,  5,  9, 13, 14, 10,  6,  
  3,  4,  7, 11, 15, 16, 12,  8,  
  17, 18, 21, 25, 26, 22, 19, 20, 
  23, 27, 31, 32, 28, 24, 30, 29,  
  33, 34, 37, 41, 42, 38, 35, 36, 
  39, 43, 47, 48, 44, 40, 46, 45,  
  49, 50, 53, 57, 58, 54, 51, 52, 
  55, 59, 63, 64, 60, 56, 62, 61 ]

Total Cycles:
Combinational... so critical path delay 
  """

@cocotb.test() 
async def rle_test(dut):
    print("starting test one")

    value = [5, 1, 2, 1, 5, 4, 3, 1, 3, 1, 5, 0, 3, 5, 1, 2, 5, 3, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    count = [3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    await cocotb.start(generate_clock(dut.clk_in))
    await reset(dut)
    print("FED DATA IN")
    while not dut.done.value:
        dut.start.value = 1
        dut.value_in.value = value
        dut.count_in.value = count

        await Timer(1,units="ns")
    await Timer(1,units="ns")
    dut.start.value = 0

    data_out_elements = dut.code_out.value
    print(data_out_elements) 
    print("\n")
    print(" ===================done wit da test ====================== ")


def sig_gen_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "huffman_encoding.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="huffman_encoding",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="huffman_encoding",
        test_module="huffman_tester",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    print("STARTING TEST \n\n\n\n ===================================================")
    sig_gen_runner()
