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

# module huffman_encoding(
#     input logic clk_in,
#     input logic rst_in,
#     input logic start,
#     input logic [7:0] value_in [0:63],   // value array 
#     input logic [7:0] count_in [0:63],   // count array 
#     output logic [1023:0] code_out,   // 16 * 64
#     output logic done
# );

    await cocotb.start(generate_clock(dut.clk_in))
    print("CLOCK GENERATED")
    await reset(dut) 
    print("FEEDING IN DATA")
    dut.start.value = 1
    dut.value_in.value = value
    dut.count_in.value = count
    print("FED DATA IN")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.start.value = 0

    data_out_elements = dut.code_out.value
    print(data_out_elements) 
    print(x)
    print("\n")
    print(" ===================done wit da test ====================== ")

@cocotb.test()
async def rand_test(dut):
    await cocotb.start(generate_clock(dut.clk_in))
    print("CLOCK GENERATED")

    _1 = [random.randint(0,5) for x in range(20)]
    _2 = [random.randint(0,5) for x in range(21)]
    _3 = [random.randint(0,5) for x in range(22)]
    _4 = [random.randint(0,5) for x in range(23)]
    _5 = [random.randint(0,5) for x in range(24)]
    _6 = [random.randint(0,5) for x in range(25)]
    _1.extend([0] * (64 - len(_1)))
    _2.extend([0] * (64 - len(_2)))
    _3.extend([0] * (64 - len(_3)))
    _4.extend([0] * (64 - len(_4)))
    _5.extend([0] * (64 - len(_5)))
    _6.extend([0] * (64 - len(_6)))
        
    print(_1)
    print(_2)
    dut.valid_in.value = 1
    dut.data_in.value = _1
    print("FED DATA IN 1")
    await reset(dut)

    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_1 = dut.run_value.value
    data_out_counts_1 = dut.run_count.value
    _g1 = int(dut.indiv_elms.value)
    await reset(dut)

    dut.valid_in.value = 1
    dut.data_in.value = _2
    print("FED DATA IN 2")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_2 = dut.run_value.value
    data_out_counts_2 = dut.run_count.value
    _g2 = int(dut.indiv_elms.value)
    await reset(dut)
    
    dut.valid_in.value = 1
    dut.data_in.value = _3
    print("FED DATA IN 3")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_3 = dut.run_value.value
    data_out_counts_3 = dut.run_count.value
    _g3 = int(dut.indiv_elms.value)
    await reset(dut)

    dut.valid_in.value = 1
    dut.data_in.value = _4
    print("FED DATA IN 4")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_4 = dut.run_value.value
    data_out_counts_4 = dut.run_count.value
    _g4 = int(dut.indiv_elms.value)
    await reset(dut)
    
    dut.valid_in.value = 1
    dut.data_in.value = _5
    print("FED DATA IN 5")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_5 = dut.run_value.value
    data_out_counts_5 = dut.run_count.value
    _g5 = int(dut.indiv_elms.value)
    await reset(dut)

    dut.valid_in.value = 1
    dut.data_in.value = _6
    print("FED DATA IN 6")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0
    data_out_elements_6 = dut.run_value.value
    data_out_counts_6 = dut.run_count.value
    _g6 = int(dut.indiv_elms.value)
    await reset(dut)



    _x1 = [int(x) for x in data_out_elements_1]
    _y1 = [int(y) for y in data_out_counts_1]
    _f1 = list(zip(_x1[:_g1],_y1[:_g1]))
    _p1 = rle_encode(_1)[:_g1]


    _x2 = [int(x) for x in data_out_elements_2]
    _y2 = [int(y) for y in data_out_counts_2]
    _f2 = list(zip(_x2[:_g2],_y2[:_g2]))
    _p2 = rle_encode(_2)[:_g2]


    _x3 = [int(x) for x in data_out_elements_3]
    _y3 = [int(y) for y in data_out_counts_3]
    _f3 = list(zip(_x3[:_g3],_y3[:_g3]))
    _p3 = rle_encode(_3)[:_g3]


    _x4 = [int(x) for x in data_out_elements_4]
    _y4 = [int(y) for y in data_out_counts_4]
    _f4 = list(zip(_x4[:_g4],_y4[:_g4]))
    _p4 = rle_encode(_4)[:_g4]

    _x5 = [int(x) for x in data_out_elements_5]
    _y5 = [int(y) for y in data_out_counts_5]
    _f5 = list(zip(_x5[:_g5],_y5[:_g5]))
    _p5 = rle_encode(_5)[:_g5]


    _x6 = [int(x) for x in data_out_elements_6]
    _y6 = [int(y) for y in data_out_counts_6]
    _f6 = list(zip(_x6[:_g6],_y6[:_g6]))
    _p6 = rle_encode(_6)[:_g6]

    assert(_p1==_f1),"pass 1 failed, womp womp"
    print("==== Passed 1 ====")
    assert(_p2==_f2),"pass 2 failed, womp womp"
    print("==== Passed 2 ====")
    assert(_p3==_f3),"pass 3 failed, womp womp"
    print("==== Passed 3 ====")
    assert(_p4==_f4),"pass 4 failed, womp womp"
    print("==== Passed 4 ====")
    assert(_p5==_f5),"pass 5 failed, womp womp"
    print("==== Passed 5 ====")
    assert(_p6==_f6),"pass 6 failed, womp womp"
    print("==== Passed 6 ====")
    print("\n\n\n")

    print("====")
    print(f"Original array is length {len(_4)}:")
    print(_4)
    print("====")
    print(f"RLE output is length {len(_f4)}:")
    print(_f4)
    print("====")
    print(data_out_counts_4)
    print(data_out_elements_4)




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
