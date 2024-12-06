import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys

from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,ReadWrite,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

from random import getrandbits

async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)

async def drive_data(dut,data_byte,control_bits,ve_bit):
    """ submit a set of data values as input, then wait a clock cycle for them to stay there. """
    dut.data_in.value = data_byte
    dut.control_in.value = control_bits
    dut.ve_in.value = ve_bit
    await ClockCycles(dut.clk_in,1)
    
@cocotb.test()
async def test_tmds(dut):
    """ Your simulation test!
        TODO: Flesh this out with value sets and print statements. Maybe even some assertions, as a treat.
    """
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # set all inputs to 0
    dut.data_in.value = 0
    dut.control_in.value = 0
    dut.ve_in.value = 0
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)

    # # example usage of the helper function to set all the input values you want to set
    # # you probably want to make lots more of these.
    # await drive_data(dut, 0x44, 0b00, 1)
    # # a clock cycle has now passed: see the helper function. read your outputs here!
    
    # await drive_data(dut, 0x55, 0b00, 1)
 
    # await reset(dut.rst_in,dut.clk_in)

    # await drive_data(dut, 0x55, 0b00, 1)
    
    # ve low 
    await drive_data(dut, 0x86, 0b01, 0)

    await drive_data(dut, 0x86, 0b00, 1)
    #1000100001

    print("\n " + str(dut.tmds_out.value) + " 10000110 ----------------------------------------\n")
    await drive_data(dut, 56, 0b00, 1)

    print("\n " + str(dut.tmds_out.value) + " 01010110----------------------------------------\n")
    await drive_data(dut, 0xFD, 0b00, 1)

    print("\n " + str(dut.tmds_out.value) + " 11111101----------------------------------------\n")

    await drive_data(dut, 0x29, 0b00, 1)

    print("\n " + str(dut.tmds_out.value) + " 00101001----------------------------------------\n")


    # assert(str(dut.tmds_out.value) == "1101010100"), f"didn't work for control 00 {str(dut.tmds_out.value)} is wrong"

    # # await reset(dut.rst_in,dut.clk_in)
    # await drive_data(dut, 0x00, 0b01, 0)
    # print("\n " + str(dut.tmds_out.value) + "----------------------------------------\n")

    # # assert(str(dut.tmds_out.value) == "0010101011"), f"didn't work for control 01 {str(dut.tmds_out.value)} is wrong"
    # # await reset(dut.rst_in,dut.clk_in)

    # # # await reset(dut.rst_in,dut.clk_in)
    # await drive_data(dut, 0x10, 0b10, 0)
    # print("\n " + str(dut.tmds_out.value) + "----------------------------------------\n")

    # # # assert(str(dut.tmds_out.value) == "0101010100"), f"didn't work for control 00 {str(dut.tmds_out.value)} is wrong"
    # # assert(str(dut.tmds_out.value) == "0101010100"), f"didn't work for control 00 {str(dut.tmds_out.value)} is wrong"

    # # await reset(dut.rst_in,dut.clk_in)
    # await drive_data(dut, 0x11, 0b11, 0)
    # print("\n " + str(dut.tmds_out.value) + "----------------------------------------\n")

    # # assert(str(dut.tmds_out.value) == "1010101011"), f"didn't work for control 00 {str(dut.tmds_out.value)} is wrong"

    # await ClockCycles(dut.clk_in,1)
    # print("\n " + str(dut.tmds_out.value) + "----------------------------------------\n")

def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "tmds_encoder.sv", proj_path / "hdl" / "tm_choice.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="tmds_encoder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="tmds_encoder",
        test_module="test_tmds",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()