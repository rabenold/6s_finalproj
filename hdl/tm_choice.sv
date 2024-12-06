module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

logic [2:0] n_1;  
assign n_1 = $countones(data_in);
always_comb begin

    qm_out[8] = (n_1> 4 || (n_1 == 4 && data_in[0] == 0)) ? 0 : 1;  
    qm_out[0] = data_in[0]; 
        if(n_1 > 4 || (n_1 == 4 && data_in[0] == 0)) begin
            for (integer j = 1; j < 8; j=j+1) begin
                qm_out[j] = data_in[j] ^~ qm_out[j-1];
            end
        end else begin
            //option 1
            for (integer j = 1; j < 8; j=j+1) begin
                qm_out[j] = data_in[j] ^ qm_out[j-1];
            end
        end
end 
endmodule