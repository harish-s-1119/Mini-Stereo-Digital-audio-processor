module R_MEM(
  input  [3:0]  RW0_addr,
  input         RW0_clk,
  input  [7:0]  RW0_wdata,
  output [7:0]  RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);
  wire [3:0] mem_0_0_A1;
  wire       mem_0_0_CE1;
  wire [7:0] mem_0_0_I1;
  wire [7:0] mem_0_0_O1;
  wire       mem_0_0_CSB1;
  wire       mem_0_0_OEB1;
  wire       mem_0_0_WEB1;
  wire [3:0] mem_0_0_A2;
  wire       mem_0_0_CE2;
  wire [7:0] mem_0_0_I2;
  wire [7:0] mem_0_0_O2;
  wire       mem_0_0_CSB2;
  wire       mem_0_0_OEB2;
  wire       mem_0_0_WEB2;
  SRAM2RW16x8 mem_0_0 (
    .A1(mem_0_0_A1),
    .CE1(mem_0_0_CE1),
    .I1(mem_0_0_I1),
    .O1(mem_0_0_O1),
    .CSB1(mem_0_0_CSB1),
    .OEB1(mem_0_0_OEB1),
    .WEB1(mem_0_0_WEB1),
    .A2(mem_0_0_A2),
    .CE2(mem_0_0_CE2),
    .I2(mem_0_0_I2),
    .O2(mem_0_0_O2),
    .CSB2(mem_0_0_CSB2),
    .OEB2(mem_0_0_OEB2),
    .WEB2(mem_0_0_WEB2)
  );
  assign RW0_rdata = mem_0_0_O1;
  assign mem_0_0_A1 = RW0_addr;
  assign mem_0_0_CE1 = RW0_clk;
  assign mem_0_0_I1 = RW0_wdata;
  assign mem_0_0_CSB1 = ~RW0_en;
  assign mem_0_0_OEB1 = ~(~RW0_wmode & RW0_en);
  assign mem_0_0_WEB1 = ~RW0_wmode;
  assign mem_0_0_A2 = RW0_addr;
  assign mem_0_0_CE2 = 1'b1;
  assign mem_0_0_I2 = RW0_wdata;
  assign mem_0_0_CSB2 = 1'b1;
  assign mem_0_0_OEB2 = 1'b1;
  assign mem_0_0_WEB2 = 1'b1;
endmodule

module CO_MEM(
  input  [8:0]  RW0_addr,
  input         RW0_clk,
  input  [8:0]  RW0_wdata,
  output reg [8:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);
  wire [11:0] mem_0_O, mem_1_O, mem_2_O, mem_3_O;
  wire        mem_OEB;
  wire        mem_WEB;
  wire        mem_0_CSB, mem_1_CSB, mem_2_CSB, mem_3_CSB;
  reg [1:0]   cs_vec;
  
  SRAM1RW128x12 mem_0_0 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I({3'b000, RW0_wdata}),
    .O(mem_0_O),
    .CSB(mem_0_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_1 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I({3'b000, RW0_wdata}),
    .O(mem_1_O),
    .CSB(mem_1_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_2 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I({3'b000, RW0_wdata}),
    .O(mem_2_O),
    .CSB(mem_2_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_3 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I({3'b000, RW0_wdata}),
    .O(mem_3_O),
    .CSB(mem_3_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  always @(mem_OEB or cs_vec or mem_0_CSB or mem_0_O or mem_1_CSB or mem_1_O or mem_2_CSB or mem_2_O or mem_3_CSB or mem_3_O) begin
    if (~mem_OEB) begin
      case (cs_vec)
        2'd0: RW0_rdata = mem_0_O[8:0];
        2'd1: RW0_rdata = mem_1_O[8:0];
        2'd2: RW0_rdata = mem_2_O[8:0];
        2'd3: RW0_rdata = mem_3_O[8:0];
      endcase
    end
  end

  always @(posedge RW0_clk) begin
    cs_vec <= RW0_addr[8:7];
  end

  assign mem_OEB = ~(RW0_en & ~RW0_wmode);
  assign mem_WEB = ~(RW0_en & RW0_wmode);
endmodule

module DATA_MEM(
  input  [7:0]  RW0_addr,
  input         RW0_clk,
  input  [15:0] RW0_wdata,
  output [15:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);
  wire [7:0] mem_0_0_A;
  wire       mem_0_0_CE;
  wire [7:0] mem_0_0_I;
  wire [7:0] mem_0_0_O;
  wire       mem_0_0_CSB;
  wire       mem_0_0_OEB;
  wire       mem_0_0_WEB;
  wire [7:0] mem_0_1_A;
  wire       mem_0_1_CE;
  wire [7:0] mem_0_1_I;
  wire [7:0] mem_0_1_O;
  wire       mem_0_1_CSB;
  wire       mem_0_1_OEB;
  wire       mem_0_1_WEB;
  SRAM1RW256x8 mem_0_0 (
    .A(mem_0_0_A),
    .CE(mem_0_0_CE),
    .I(mem_0_0_I),
    .O(mem_0_0_O),
    .CSB(mem_0_0_CSB),
    .OEB(mem_0_0_OEB),
    .WEB(mem_0_0_WEB)
  );
  SRAM1RW256x8 mem_0_1 (
    .A(mem_0_1_A),
    .CE(mem_0_1_CE),
    .I(mem_0_1_I),
    .O(mem_0_1_O),
    .CSB(mem_0_1_CSB),
    .OEB(mem_0_1_OEB),
    .WEB(mem_0_1_WEB)
  );
  assign RW0_rdata = {mem_0_1_O, mem_0_0_O};
  assign mem_0_0_A = RW0_addr;
  assign mem_0_0_CE = RW0_clk;
  assign mem_0_0_I = RW0_wdata[7:0];
  assign mem_0_0_CSB = ~RW0_en;
  assign mem_0_0_OEB = ~(~RW0_wmode & RW0_en);
  assign mem_0_0_WEB = ~RW0_wmode;
  assign mem_0_1_A = RW0_addr;
  assign mem_0_1_CE = RW0_clk;
  assign mem_0_1_I = RW0_wdata[15:8];
  assign mem_0_1_CSB = ~RW0_en;
  assign mem_0_1_OEB = ~(~RW0_wmode & RW0_en);
  assign mem_0_1_WEB = ~RW0_wmode;
endmodule

