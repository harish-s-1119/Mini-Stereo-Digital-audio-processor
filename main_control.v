module MAIN_CTRL(
  input Sclk, Start, Reset_n, Frame_sync,
  input all_zero,
  input in_data_ready_sync, // Synchronized in_data_ready
  output reg InReady,
  output ALU_calc,
  output reg mem_clear_data, mem_R_en, mem_Co_en, mem_In_en, mem_r0w1,
  output [8:0] mem_addr
);
  parameter INIT=0;
  parameter WAIT_R=1;
  parameter READ_R=2;
  parameter WAIT_CO=3;
  parameter READ_CO=4;
  parameter WAIT_IN=5;
  parameter WORK=6;
  parameter CLEAR=7;
  parameter SLEEP=8;
  
  reg [3:0] state, next_state;
  reg ctrl_incr_addr, ctrl_reset_addr, ctrl_incr_zero_cnt, ctrl_reset_zero_cnt;
  reg [9:0] addr_iter, zero_cnt;
  reg in_data_ready_d0;
  wire in_data_ready_pules;
  
  // FSM control (combinational logic)
  always @(state or Frame_sync or addr_iter or in_data_ready_pules or all_zero or zero_cnt) begin
    case (state)
      INIT: begin
        ctrl_incr_addr = 1;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b111;
        mem_r0w1 = 1;
        mem_clear_data = 1;
        InReady = 0;
        if (addr_iter == 9'h1FF)
          next_state = WAIT_R;
        else
          next_state = INIT;
      end
      WAIT_R: begin
        ctrl_incr_addr = 0;
        ctrl_reset_addr = 1;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b000;
        mem_r0w1 = 0;
        mem_clear_data = 0;
        InReady = 1;
        if (Frame_sync)
          next_state = READ_R;
        else
          next_state = WAIT_R;
      end
      READ_R: begin
        ctrl_incr_addr = in_data_ready_pules;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = {in_data_ready_pules, 1'b0, 1'b0};
        mem_r0w1 = 1;
        mem_clear_data = 0;
        InReady = 1;
        if (addr_iter == 10'd16)
          next_state = WAIT_CO;
        else
          next_state = READ_R;
      end
      WAIT_CO: begin
        ctrl_incr_addr = 0;
        ctrl_reset_addr = 1;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b000;
        mem_r0w1 = 0;
        mem_clear_data = 0;
        InReady = 1;
        if (Frame_sync)
          next_state = READ_CO;
        else
          next_state = WAIT_CO;
      end
      READ_CO: begin
        ctrl_incr_addr = in_data_ready_pules;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = {1'b0, in_data_ready_pules, 1'b0};
        mem_r0w1 = 1;
        mem_clear_data = 0;
        InReady = 1;
        if (addr_iter == 10'd512)
          next_state = WAIT_IN;
        else
          next_state = READ_CO;
      end
      WAIT_IN: begin
        ctrl_incr_addr = 0;
        ctrl_reset_addr = 1;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b000;
        mem_r0w1 = 0;
        mem_clear_data = 0;
        InReady = 1;
        if (Frame_sync)
          next_state = WORK;
        else
          next_state = WAIT_IN;
      end
      WORK: begin
        ctrl_incr_addr = in_data_ready_pules;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = in_data_ready_pules && all_zero;
        ctrl_reset_zero_cnt = in_data_ready_pules && ~all_zero;
        {mem_R_en, mem_Co_en, mem_In_en} = {~in_data_ready_pules, ~in_data_ready_pules, 1'b1};
        mem_r0w1 = in_data_ready_pules;
        mem_clear_data = 0;
        InReady = 1;
        if (zero_cnt == 10'd800)
          next_state = SLEEP;
        else
          next_state = WORK;
      end
      CLEAR: begin
        ctrl_incr_addr = 1;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 1;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b001;
        mem_r0w1 = 1;
        mem_clear_data = 1;
        InReady = 0;
        if (addr_iter == 10'd255)
          next_state = WAIT_IN;
        else
          next_state = CLEAR;
      end
      SLEEP: begin
        ctrl_incr_addr = in_data_ready_pules;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = in_data_ready_pules && ~all_zero;
        {mem_R_en, mem_Co_en, mem_In_en} = {~in_data_ready_pules, ~in_data_ready_pules, ~all_zero};
        mem_r0w1 = in_data_ready_pules;
        mem_clear_data = 0;
        InReady = 1;
        if (in_data_ready_pules && ~all_zero)
          next_state = WORK;
        else
          next_state = SLEEP;
      end
      default: begin
        ctrl_incr_addr = 0;
        ctrl_reset_addr = 0;
        ctrl_incr_zero_cnt = 0;
        ctrl_reset_zero_cnt = 0;
        {mem_R_en, mem_Co_en, mem_In_en} = 3'b000;
        mem_r0w1 = 0;
        mem_clear_data = 0;
        InReady = 0;
        next_state = INIT;
      end
    endcase
  end

  assign mem_addr = addr_iter;
  assign ALU_calc = (state == WORK) && in_data_ready_pules;
  
  // State register (sequential)
  always @(posedge Sclk or posedge Start) begin
    if (Start)
      state <= INIT;
    else if (~Reset_n)
      state <= CLEAR;
    else
      state <= next_state;
  end

  // Address iterator (sequential)
  always @(posedge Sclk or posedge Start) begin
    if (Start)
      addr_iter <= 0;
    else if (ctrl_reset_addr || ~Reset_n)
      addr_iter <= 0;
    else if (ctrl_incr_addr)
      addr_iter <= addr_iter + 1;
  end

  // All-zero input counter (sequential)
  always @(posedge Sclk or posedge Start) begin
    if (Start)
      zero_cnt <= 0;
    else if (ctrl_reset_zero_cnt || ~Reset_n)
      zero_cnt <= 0;
    else if (ctrl_incr_zero_cnt)
      zero_cnt <= zero_cnt + 1;
  end

  // Synchronize in_data_ready (one-cycle pulse generation)
  always @(posedge Sclk or posedge Start) begin
    if (Start)
      in_data_ready_d0 <= 0;
    else if (~Reset_n)
      in_data_ready_d0 <= 0;
    else
      in_data_ready_d0 <= in_data_ready_sync;
  end
  assign in_data_ready_pules = in_data_ready_sync & ~in_data_ready_d0;
endmodule

