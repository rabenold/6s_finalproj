import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner


@cocotb.test()
async def test_one(dut):
    in_one = 0b11111110    #[1,1,1,1,1,1,1,1]
    out_one = "000000000"
    in_two = 0b00000001  #[0,0,0,0,0,0,0,1]
    out_two = "111111111"
    dut.data_in.value = in_one;
    await Timer(5, units="ns")
    assert (str(dut.qm_out.value) == out_one), f"in one don't equal out one {out_one} != {dut.qm_out.value}"
    await Timer(5, units="ns")
    dut.data_in.value = in_two;
    await Timer(10, units="ns")
    assert (dut.qm_out.value == out_two), f"in two don't equal out two {out_two} != {dut.qm_out.value}"


def sig_gen_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "tm_choice.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="tm_choice",
        always=True,
        
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="tm_choice",
        test_module="tm_choice_tester",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    print("STARTING TEST \n\n ===================================================")
    sig_gen_runner()