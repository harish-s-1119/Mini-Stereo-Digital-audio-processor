module ALU(
  input Sclk, uni_reset_n,
  input ALU_calc,
  input [7:0] input_cnt,
  output reg ppl_stall, ALU_finish,
  output [39:0] output_data,
  
  input [7:0] R_mem_data,
  input [8:0] Co_mem_data,
  input [15:0] Data_mem_data,
  output [3:0] R_mem_addr,
  output [8:0] Co_mem_addr,
  output [7:0] Data_mem_addr
);
  parameter WAIT=0;
  parameter RESET=1;
  parameter CALC=2; // Do calculation
  parameter OUTPUT=3; // Output 40-bit data in parallel
  
  reg [1:0] state, next_state;
  reg signed [39:0] ex, y, y_tmp;
  reg [9:0] ite;
  reg [8:0] ite_delay[1:3], R_accu, k;
  wire [7:0] n;
  reg ppl_rst, ppl_run, R_was_1;
  reg [4:0] j;
  reg sign_delay;
  wire [8:0] ite_delay3_plus1;
  
  // State register and R monitor
  always @(posedge Sclk or negedge uni_reset_n) begin
    if (~uni_reset_n) begin
      state <= WAIT;
      R_was_1 <= 0;
    end else begin
      state <= next_state;
      R_was_1 <= (R_mem_data == 1);
    end
  end

  // ALU control logic (state machine)
  assign ite_delay3_plus1 = ite_delay[2];
  // assign ite_delay3_plus2 = ite_delay[1]; // not used

  always @(state or ALU_calc or ite_delay[1] or R_accu or j) begin
    case (state)
      WAIT: begin
        ALU_finish = 0;
        ppl_rst = 0;
        ppl_run = 0;
        if (ALU_calc)
          next_state = RESET;
        else
          next_state = WAIT;
      end
      RESET: begin
        ALU_finish = 0;
        ppl_rst = 1;
        ppl_run = 0;
        next_state = CALC;
      end
      CALC: begin
        ALU_finish = 0;
        ppl_rst = 0;
        ppl_run = 1;
        if ((ite_delay3_plus1 == R_accu) && j[4])
          next_state = OUTPUT;
        else
          next_state = CALC;
      end
      OUTPUT: begin
        ALU_finish = 1;
        ppl_rst = 0;
        ppl_run = 0;
        next_state = WAIT;
      end
    endcase
  end

  assign output_data = y;
  
  // Calculation pipeline
  always @(posedge Sclk or negedge uni_reset_n) begin
    if (~uni_reset_n) begin
      y <= 0;
      ite <= 0;
      ite_delay[1] <= 0;
      ite_delay[2] <= 0;
      ite_delay[3] <= 0;
      sign_delay <= 0;
      R_accu <= 0;
      j <= 0;
      k <= 0;
    end else if (ppl_rst) begin
      y <= 0;
      ite <= 0;
      ite_delay[1] <= 0;
      ite_delay[2] <= 0;
      ite_delay[3] <= 0;
      sign_delay <= 0;
      R_accu <= R_mem_data;
      j <= 0;
      k <= 0;
    end else if (ppl_run) begin
      // Stall the pipeline if R[j] == 1
      if (R_mem_data != 1) begin
        // 1. Fetch coefficient index (k)
        k <= ite[8:0];
        ite <= ite + 1;
        ite_delay[1] <= ite[8:0];

        // 2. Prepare input data index x(n-k)
        ite_delay[2] <= ite_delay[1];

        // 3. Stall for memory read; fetch next R bit
        sign_delay <= Co_mem_data[8];
        ite_delay[3] <= ite_delay[2];
      end
      if ((ite_delay[2] == R_accu) || ((R_mem_data == 1) && ~R_was_1)) begin
        // Enforce increment of R index if a new R value is 1
        j <= j + 1;
      end

      if (R_mem_data != 1) begin
        // 4. Accumulate y; shift right if end of calculation loop
        // (y_tmp is calculated in the next always block)
        if (ite >= 3) begin
          if (ite_delay3_plus1 == R_accu)
            y <= (y_tmp >>> 1);
          else
            y <= y_tmp;
        end
      end
      if ((ite_delay[3] == R_accu) || ((R_mem_data != 1) && R_was_1)) begin
        R_accu <= R_accu + R_mem_data;
      end
    end
  end

  assign ppl_stall = (R_mem_data == 1);
  assign Data_mem_addr = n - Co_mem_data[7:0];

  // Combine current data and sign for accumulation
  always @(y or sign_delay or Data_mem_data or R_was_1) begin
    if (R_was_1)
      ex = 0;
    else
      ex = {{8{Data_mem_data[15]}}, Data_mem_data, 16'h0};

    if (sign_delay)
      y_tmp = y - ex;
    else
      y_tmp = y + ex;
  end
   
  assign R_mem_addr = j[3:0];
  assign Co_mem_addr = k;
  assign n = input_cnt - 1;
endmodule

