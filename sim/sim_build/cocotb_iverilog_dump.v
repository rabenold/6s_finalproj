module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/raben/Desktop/Schuul/6S/stuff/fpstuf/6s_finalproj/sim/sim_build/rgb_to_ycbcr.fst");
    $dumpvars(0, rgb_to_ycbcr);
end
endmodule
