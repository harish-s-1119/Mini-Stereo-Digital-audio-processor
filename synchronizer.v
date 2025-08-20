module SYNC(
  input clk, uni_reset_n,
  input sync_in,
  output reg sync_out
);
  reg sync_med;
  
  always @(posedge clk or negedge uni_reset_n) begin
    if (~uni_reset_n) begin
      sync_med <= 0;
      sync_out <= 0;
    end else begin
      sync_med <= sync_in;
      sync_out <= sync_med;
    end
  end
endmodule

