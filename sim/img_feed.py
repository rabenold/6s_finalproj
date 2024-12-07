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


    #wait how long? 


class RGB_IN(BusDriver):
    def __init__(self,dut,name,clk_in):
        self._signals = ["r_in","g_in","b_in"]
 
        BusDriver.__init__(self, dut, name, clk_in)
        self.clock = clk_in

    async def _driver_send(self,value,sync=True):
        await RisingEdge(self.clock)
        self.bus.r_in = (value >> 16) & 0xFF  # Extract the red channel (bits 23:16)
        self.bus.g_in = (value >> 8) & 0xFF   # Extract the green channel (bits 15:8)
        self.bus.b_in = value & 0xFF

class YCbCR_OUT(BusMonitor):
    transactions = 0 
    def __init__(self,dut,name,clk_in):
        self._signals = ["y_out","cb_out","cr_out"]
        BusMonitor.__init__(self, dut, name, clk_in)
        self.pixels_out = [] 
        self.clock = clk_in
        self.transactions = 0 
        

    async def _monitor_recv(self):
        print("hello")
        while True: 
            await RisingEdge(self.clock)
            # print("toggled")
            print(f" y out {self.bus.y_out} \n")
            if self.bus.y_out is not None:
                
                y = self.bus.y_out.value 
                cb = self.bus.cb_out.value
                cr = self.bus.cr_out.value 
                self.pixels_out.append(y<<16|cb<<8|cr)
                self.transactions+=1 
                print(self.transactions)



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
    
    return int(Y)<<16 | int(Cb)<< 8 | int(Cr) 


@cocotb.test()
async def testone(dut):
    #test one. loads a val then waits 3 clock cycles for the output. need ta fix monitor and driver so that we don't have to wait 
    await cocotb.start(generate_clock(dut.clk_in))  
    await RisingEdge(dut.clk_in)  # Wait for the first clock edge to stabilize
    arr = []
    ans_arr = []
    out_arr = [] 
    for i in range(0,50): 
        x = random.randint(0,0xFFFFFF)
        arr.append(x)
        ans_arr.append(rgb_to_ycbcr(x))
    for value in arr:
        await RisingEdge(dut.clk_in)  # Wait for the first clock edge to stabilize
        dut.r_in.value = (value >> 20) & 0x3FF  # Extract the red channel (bits 23:16)
        dut.g_in.value = (value >> 10) & 0x3FF   # Extract the green channel (bits 15:8)
        dut.b_in.value = value & 0x3FF
        await ClockCycles(dut.clk_in,3)
        y_out = dut.y_out.value
        cb_out = dut.cb_out.value
        cr_out = dut.cr_out.value 
        if 'x' not in str(y_out): 
            out_arr.append(y_out<<16 | cb_out<<8 | cr_out)
    
    for j in range(0,len(out_arr)):
        # print(f"{ans_arr[j]} == {out_arr[j]}\n")
        assert ans_arr[j]==out_arr[j], f"expected{ans_arr[j]} != result {out_arr[j]}\n"
    print(f"\n ============ Passed test {testone.__name__}============ \n")

def ycbcr2rgb(ycbcr):
    # Convert YCbCr to RGB using the inverse of the RGB to YCbCr conversion formula
    y, cb, cr = ycbcr
    r = y + 1.402 * (cr - 128)
    g = y - 0.344136 * (cb - 128) - 0.714136 * (cr - 128)
    b = y + 1.772 * (cb - 128)
    return np.clip([r, g, b], 0, 255)


@cocotb.test()
async def test_image(dut):
    path = '../sim/rgb.jpg'
    img = Image.open(path).convert('RGB')
    await cocotb.start(generate_clock(dut.clk_in))  
    await RisingEdge(dut.clk_in)  # Wait for the first clock edge to stabilize
    image_arr = np.array(img) #conv to np arr 
    height,width, _ = image_arr.shape #get dimensions
    image_arr = image_arr 
    print(f"HEIGHT is {height} + WIDTH is {width} ================================ \n")
    y_channel = []
    cb_channel = []
    cr_channel = []
    arr = [int(pix[0] << 16) | int(pix[1] << 8) | int(pix[2]) for pix in image_arr.reshape(-1, 3)]
    ans_arr = [rgb_to_ycbcr(pix) for pix in arr]
    out_arr = [] 
    print(f"Array init to len {len(arr)}, type {type(arr[0])}")
    for value in arr:
        await RisingEdge(dut.clk_in)  # Wait for the first clock edge to stabilize
        dut.r_in.value = (value >> 16) & 0xFF  # Extract the red channel (bits 23:16)
        dut.g_in.value = (value >> 8) & 0xFF   # Extract the green channel (bits 15:8)
        dut.b_in.value = value & 0xFF
        await ClockCycles(dut.clk_in,3)
        y_out = dut.y_out.value
        cb_out = dut.cb_out.value
        cr_out = dut.cr_out.value 
        if 'x' not in str(y_out): 
            out_arr.append(y_out<<16 | cb_out<<8 | cr_out)
            y_channel.append(y_out)
            cb_channel.append(cb_out)
            cr_channel.append(cr_out)
    for j in range(0,len(out_arr)-1):
        # print(f"{ans_arr[j]} == {out_arr[j+1]}\n")
        assert ans_arr[j]==out_arr[j+1], f"expected{ans_arr[j]} != result {out_arr[j+1]} index = {j}\n"
        # pass 
    print(f"\n ============ Passed test {test_image.__name__}============ \n")

    # print(out_arr)
    h,w, = img.size
    print(f"Length of y_channel: {len(y_channel)}")
    print(f"First few entries in y_channel: {y_channel[:10]}")  # Show first 10 values
    y_channel = [int(item) for item in y_channel]

    # Clip values to fit within the range of np.uint8 (0 to 255)
    y_channel = [max(0, min(255, item)) for item in y_channel]

    # Create the NumPy array
    try:
        y_arr = np.array(y_channel, dtype=np.uint8)
        print(f"y_arr shape: {y_arr.shape}")  # Should be (60000,)
        print(f"First few values in y_arr: {y_arr[:10]}")
    except Exception as e:
        print(f"Error during conversion: {e}")

    # # Check the result
    # print(f"y_arr shape: {y_arr.shape}")  # Should be (60000,)
    # print(f"First few values in y_arr: {y_arr[:10]}")
    # y_arr = np.array(y_channel,dtype=np.uint8)  
    # cb_arr = np.array(cb_channel,dtype=np.uint8)  
    # cr_arr = np.array(cr_channel,dtype=np.uint8)    
    # Reshape the array into the image dimensions (height, width, 3)
    print("arrs generated")
    ycbcr_image = np.stack((y_channel, cb_channel, cr_channel), axis=-1).reshape((h, w, 3))
    
    # Optionally, you can convert YCbCr to RGB if you want to display it
    rgb_image = ycbcr2rgb(ycbcr_image)  # Assuming you have a function to convert YCbCr to RGB
    print("First 10 RGB values:", rgb_image[:10])
    # plt.axis('off')  # Turn off the axis labels
    # plt.show()
    # Y_channel = (new_image_arr >> 12) & 0xFF  # Extract the Y channel (top 8 bits)
    # Cb_channel = (new_image_arr >> 4) & 0xFF  # Extract the Cb channel (middle 8 bits)
    # Cr_channel = new_image_arr & 0xFF         # Extract the Cr channel (bottom 8 bits)

    plt.imshow(rgb_image)
    plt.show()
    # fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    # axes[0].imshow(Y_channel)
    # axes[0].set_title('Y Channel (Luminance)')
    # axes[0].axis('off')
    # # Plot Cb channel
    # axes[1].imshow(Cb_channel)
    # axes[1].set_title('Cb Channel (Chrominance)')
    # axes[1].axis('off')
    # # Plot Cr channel
    # axes[2].imshow(Cr_channel)
    # axes[2].set_title('Cr Channel (Chrominance)')
    # axes[2].axis('off')
    # plt.tight_layout()
    # plt.show()








def test_color_conv():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "rgb_to_ycbcr.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="rgb_to_ycbcr",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="rgb_to_ycbcr",
        test_module="img_feed",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_color_conv()