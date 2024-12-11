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



async def generate_clock(clock_wire):
    while True: # repeat forever
        clock_wire.value = 0
        await Timer(5,units="ns")
        clock_wire.value = 1
        await Timer(5,units="ns")


    #wait how long? 


# async def test_rgb(dut):


#     image_arr = np.array(img) #conv to np arr 
#     height,width, _ = image_arr.shape #get dimensions 
#     print(f"HEIGHT is {height} + WIDTH is {width} ================================ \n")
    
#     rgb_driver = RGB_IN(dut,"rgb_driver",dut.clk_in)
#     print("Driver init ================================ \n")
#     ycbcr_monitor = YCbCR_OUT(dut,"ycbcr_monitor",dut.clk_in)
#     print("Monitor init ================================ \n")
#     await cocotb.start_soon(ycbcr_monitor._monitor_recv())
#     print("MONITOR started ================================ \n")
#     pixel_stream = []  
#     for y in range(height):
#         for x in range(width):
#             r,g,b = image_arr[y,x]
#             one_pixel = (r<<16) | (g<<8) | b   #smoosh into one pixel ls
#             pixel_stream.append(one_pixel)
#             print(f"pixel  {one_pixel}")
#             #sv takes color channels independently but eh whatevs 
#     for pixel in pixel_stream: 
#         await rgb_driver._driver_send(pixel)
#         await ClockCycles(dut.clk_in,1)
#         # await cocotb.sleep(0.01)


def extract_bits(value, high_bit, low_bit):
    # Mask the higher bits and shift the value to extract the desired range
    return (value >> low_bit) & ((1 << (high_bit - low_bit + 1)) - 1)

def rgb_to_ycbcr(value):
    #use the same formula as the verilog 
    R = (value >> 20) & 0x3FF  # Extract the red channel (bits 23:16)
    G = (value >> 10) & 0x3FF   # Extract the green channel (bits 15:8)
    B = value & 0x3FF

    yr = 0x132 * R
    yg = 0x259 * G
    yb = 0x074 * B
    y1 = yr + yg + yb 

    crr = R<<9
    crg = 0x1ad * G
    crb = 0x053 * B
    cr1 = crr - crg - crb

    cbr = 0x0ad * R 
    cbg = 0x153 * G
    cbb = B<<9
    cb1 = cbb - cbr - cbg

    Y = extract_bits(y1, 19, 10)
    Cr = extract_bits(cr1, 19, 10)
    Cb = extract_bits(cb1, 19, 10)
    
    return int(Y),int(Cb), int(Cr) 


@cocotb.test()
async def testone(dut):
    #TAKES 64 clock cycles 


    #test one. loads a val then waits 3 clock cycles for the output. need ta fix monitor and driver so that we don't have to wait 
    await cocotb.start(generate_clock(dut.clk_in))  
    await RisingEdge(dut.clk_in)  # Wait for the first clock edge to stabilize
    

    r_channel = [random.randint(0, 63) for _ in range(64)]  # 8x8 array for Red channel (10-bit values)
    g_channel = [random.randint(0, 31) for _ in range(64)]  # 8x8 array for Red channel (10-bit values)
    b_channel = [random.randint(0, 63) for _ in range(64)]  # 8x8 array for Red channel (10-bit values)

    dut.reset.value = 1
    await ClockCycles(dut.clk_in,1)
    dut.reset.value = 0
    await ClockCycles(dut.clk_in,1)
    await RisingEdge(dut.clk_in)
    
    while not dut.done.value and dut.ready.value:
    # Assigning individual pixel values for the 8x8 matrix to the Verilog signals
        await ClockCycles(dut.clk_in,1)
        for i in range(8):
            for j in range(8):
                dut.r_in.value = r_channel  # Assign each element
                dut.g_in.value = g_channel  # Assign each element
                dut.b_in.value = b_channel  # Assign each element
    await ClockCycles(dut.clk_in,64)
    
    y_out = dut.y_out.value 

    cb_out = dut.cb_out.value 
    cr_out = dut.cr_out.value 

    print(y_out, len(y_out))
 

def ycbcr2rgb(ycbcr):
    # Convert YCbCr to RGB using the inverse of the RGB to YCbCr conversion formula
    y, cb, cr = ycbcr
    r = y + 1.402 * (cr - 128)
    g = y - 0.344136 * (cb - 128) - 0.714136 * (cr - 128)
    b = y + 1.772 * (cb - 128)
    return np.clip([r, g, b], 0, 255)








def test_color_conv():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "mat_rgb_ycbcr.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="rgb_to_ycbcr_8x8",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="rgb_to_ycbcr_8x8",
        test_module="rgb_ycbcr_mat_tester",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_color_conv()