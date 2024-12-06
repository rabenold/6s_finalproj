module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/raben/Desktop/Schuul/6S/stuff/fpstuf/6s_finalproj/sim_build/rgb_conv.fst");
    $dumpvars(0, rgb_conv);
end
endmodule
