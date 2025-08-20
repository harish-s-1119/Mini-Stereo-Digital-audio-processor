module SERIAL_2_PARALLEL(
  input Dclk, uni_reset_n,
  input Frame, InputL, InputR,
  output in_data_ready, all_zero,
  output [15:0] in_data_L, in_data_R
);
  reg [15:0] data_L, data_R;
  reg [3:0] cnt;
  reg state, next_state;
  
  // Serial input state machine (LSB-first)
  always @(cnt or Frame or state) begin
    case (state)
      1'b0: next_state = Frame;
      1'b1: next_state = ((cnt != 14) || Frame);
    endcase
  end
  
  always @(negedge Dclk or negedge uni_reset_n) begin
    if (~uni_reset_n) 
      state <= 1'b0;
    else
      state <= next_state;
  end
  
  // Bit counter
  always @(negedge Dclk or negedge uni_reset_n) begin
    if (~uni_reset_n)
      cnt <= 0;
    else if (Frame)
      cnt <= 0;
    else if (state == 1'b1)
      cnt <= cnt + 1;
  end
  
  // Shift register for input data
  always @(negedge Dclk or negedge uni_reset_n) begin
    if (~uni_reset_n) begin
      data_L <= 0;
      data_R <= 0;
    end else begin
      data_L <= {InputL, data_L[15:1]};
      data_R <= {InputR, data_R[15:1]};
    end
  end
  
  assign in_data_ready = (cnt == 15);
  assign all_zero = (data_L == 0) && (data_R == 0);
  assign in_data_L = data_L;
  assign in_data_R = data_R;
endmodule

module PARALLEL_2_SERIAL(
  input Sclk, uni_reset_n,
  input ALU_finish_L, ALU_finish_R,
  input [39:0] ALU_out_L, ALU_out_R,
  output reg OutReady, OutputL, OutputR
);
  reg state, next_state;
  reg loaded_L, loaded_R;
  reg [39:0] data_L, data_R;
  reg [5:0] cnt;
  
  // State register
  always @(posedge Sclk or negedge uni_reset_n) begin
    if (~uni_reset_n)
      state <= 1'b0;
    else
      state <= next_state;
  end
  
  // Output logic (FSM for output bits)
  always @(state or loaded_L or loaded_R or data_L or data_R or cnt) begin
    case (state)
      1'b0: begin
        OutReady = 0;
        OutputL = 0;
        OutputR = 0;
        next_state = (loaded_L && loaded_R);
      end
      1'b1: begin
        OutReady = 1;
        OutputL = data_L[0];
        OutputR = data_R[0];
        next_state = (cnt != 39);
      end
    endcase
  end
  
  // Data loading and shifting
  always @(posedge Sclk or negedge uni_reset_n) begin
    if (~uni_reset_n) begin
      data_L <= 0;
      data_R <= 0;
      loaded_L <= 0;
      loaded_R <= 0;
    end else if (state == 1'b0) begin
      if (ALU_finish_L) begin
        data_L <= ALU_out_L;
        loaded_L <= 1;
      end
      if (ALU_finish_R) begin
        data_R <= ALU_out_R;
        loaded_R <= 1;
      end
    end else if (state == 1'b1) begin
      data_L <= {1'b0, data_L[39:1]};
      data_R <= {1'b0, data_R[39:1]};
      loaded_L <= 0;
      loaded_R <= 0;
    end
  end
  
  // Bit counter for output shift
  always @(posedge Sclk or negedge uni_reset_n) begin
    if (~uni_reset_n)
      cnt <= 0;
    else if (state == 1'b0)
      cnt <= 0;
    else 
      cnt <= cnt + 1;
  end
endmodule

