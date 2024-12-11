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
def rle_encode(input_list):
    # Ensure the input list is not empty
    if not input_list:
        return [], []

    # Initialize variables to store the result
    run_values = []
    run_counts = []

    # Initialize the first value and the count
    current_value = input_list[0]
    count = 1

    # Iterate through the input list starting from the second element
    for i in range(1, len(input_list)):
        if input_list[i] == current_value:
            # If the current value matches the previous, increment the count
            count += 1
        else:
            # Otherwise, store the current run and reset for the next run
            run_values.append(current_value)
            run_counts.append(count)
            current_value = input_list[i]
            count = 1  # Reset count for the new value

    # Append the last run
    run_values.append(current_value)
    run_counts.append(count)
    print(" sum run counts")
    print(sum(run_counts))
    o = [(x,y) for x, y in list(zip(run_values,run_counts))]
    return o

@cocotb.test() 
async def rle_test(dut):
    print("starting test one")
    zig_zag =[100, 95, 0, 0, 0, 80, 70, 0, 0, 0, 60, 0, 50, 0, 0, 0, 0, 40, 35, 0, 0, 25, 0, 0, 0, 0, 0, 0, 0, 20, 10, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    # bin_zag = [bin(x)[2:] for x in zig_zag] 
    # print(bin_zag)

    print("=============zig zag\n\n")
    # bin_str = int_array_to_binary_string(zig_zag)
    # my_str = '0110010001011111'
    # print(run_length_encoding(bin_str))
    await cocotb.start(generate_clock(dut.clk_in))
    print("CLOCK GENERATED")
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,1)
    print("FEEDING IN DATA")
#    zig_zag = [ 1,  2,  5,  9, 13, 14, 10,  6,  3,  4,  7, 11, 15, 16, 12,  8,  17, 18, 21, 25, 26, 22, 19, 20, 23, 27, 31, 32, 28, 24, 30, 29,  33, 34, 37, 41, 42, 38, 35, 36, 39, 43, 47, 48, 44, 40, 46, 45,  49, 50, 53, 57, 58, 54, 51, 52, 55, 59, 63, 64, 60, 56, 62, 61 ]
    dut.valid_in.value = 1
    dut.data_in.value = zig_zag
    print("FED DATA IN")
    while not dut.done.value:
        await Timer(1,units="ns")
    dut.valid_in.value = 0

    data_out_elements = dut.run_value.value
    data_out_counts = dut.run_count.value
    print(data_out_elements) 
    x = []
    y= [] 
    for elem in data_out_elements:
        if isinstance(elem, cocotb.binary.BinaryValue):  # Check if the element is a BinaryValue
            try:
                x.append(elem.integer)  # Convert BinaryValue to its integer representation
            except ValueError:
                pass  # Skip invalid BinaryValue elements that cannot be converted to integers

    for elem in data_out_counts:
        if isinstance(elem, cocotb.binary.BinaryValue):  # Check if the element is a BinaryValue
            try:
                y.append(elem.integer)  # Convert BinaryValue to its integer representation
            except ValueError:
                pass 

    # print(data_out_elements)
    # print(data_out_counts)
    # x.reverse()
    # y.reverse() 
    print(x)
    print("\n")
    print(y)
    print("\n======")
    q = sum(y)
    print(q)
    g = int(dut.indiv_elms.value)
    print(g)

    print(x[:g])
    print(y[:g])
    f = list(zip(x[:g],y[:g]))
    print("sv output: ")
    print(f)
    print("py output: ")
    p = rle_encode(zig_zag)[:g]
    print(p)
    assert(p==f),"womp womp"

    print(" ===================done wit da test ====================== ")
def sig_gen_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "run_length_encoding.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="rle_encoder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="rle_encoder",
        test_module="rle_tester",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    print("STARTING TEST \n\n\n\n ===================================================")
    sig_gen_runner()
