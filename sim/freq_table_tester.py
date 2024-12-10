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
    dut.valid_in.value = 0 
    dut.rst_in.value = 1; 
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,4)

async def drive_data(dut,value):
    dut.data_in.value = value

def freq_arr_gen(arr):
    freq_arr = [0]*len(arr)
    x = [int(x) for x in arr]
    for val in x: 
        freq_arr[val] += 1
    return freq_arr

@cocotb.test() 
async def test_one(dut):
    print("========= Starting Test =========")
    arr = []
    sv_freq_arr = []
    coco_freq_arr = []
    arr_len = 256
    for i in range(arr_len):
        arr.append(random.randint(0,arr_len-1))  #list of 16 bit ints 
    # arr done 
    assert(len(arr) == arr_len), "FUCK YOU"
    print("========= Array Generated =========")
    await cocotb.start(generate_clock(dut.clk_in))
    print("CLOCK GENERATED")
    await reset(dut)
    t_start = gst() 
    print(f"STARTING TABLE GEN at t = {t_start}")
    await ClockCycles(dut.clk_in,1)
    if(dut.ready.value):
        await RisingEdge(dut.clk_in)
        dut.valid_in.value = 1
        arr.reverse() #TODO THIS IS IMPORTANT - feed in from msb; remove if from LSB 
        for i in arr:
                dut.data_in.value = i 
                # await drive_data(dut,i)
                # await FallingEdge(dut.clk_in)
                await ClockCycles(dut.clk_in,1)
    t_end = gst() 
    dut.valid_in.value = 0
    await ClockCycles(dut.clk_in,300)
    # await ReadOnly()
    sv_freq_arr = dut.freq_table_out.value 
    
    print(f"DONE at t = {t_end}")
    coco_freq_arr = freq_arr_gen(arr)
    coco_freq_arr.reverse() #IF DOING MSB of arr KEEP 
    bin_arr = [int(x) for x in sv_freq_arr]
    # bin_arr.reverse()  #if doing LSB KEEP THIS 
    print(bin_arr[:10])
    print(coco_freq_arr[:10])
    assert(len(bin_arr)==arr_len),"output arr len wrong uh oh!"
    assert(len(sv_freq_arr)==arr_len),"output arr len wrong uh oh!"
    assert(bin_arr == coco_freq_arr),f"arrays not equal, suckaaaaaah {bin_arr} != {coco_freq_arr}"
    print(f"========= Done in {t_end-t_start} UNITS =========")

def freq_tester():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "frequency_table.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="frequency_table",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="frequency_table",
        test_module="freq_table_tester",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    freq_tester()