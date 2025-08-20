`timescale 1ns/1ps

module SRAM2RW16x8 (A1, CE1, I1, O1, CSB1, OEB1, WEB1,
                    A2, CE2, I2, O2, CSB2, OEB2, WEB2);

input  [4-1:0] A1;
input          CE1;
input  [8-1:0] I1;
output [8-1:0] O1;
input          CSB1;
input          OEB1;
input          WEB1;

input  [4-1:0] A2;
input          CE2;
input  [8-1:0] I2;
output [8-1:0] O2;
input          CSB2;
input          OEB2;
input          WEB2;

reg    [8-1:0] memory[16-1:0];
reg    [8-1:0] data_out1, data_out2;
wire   [8-1:0] O1, O2;

wire RE1, RE2;
wire WE1, WE2;
and u3 (RE1, ~CSB1, ~OEB1);
and u4 (WE1, ~CSB1, ~WEB1);
and u5 (RE2, ~CSB2, ~OEB2);
and u6 (WE2, ~CSB2, ~WEB2);

always @ (posedge CE1) begin
    if (RE1)
        data_out1 <= memory[A1];
    if (WE1)
        memory[A1] <= I1;
end

always @ (posedge CE2) begin
    if (RE2)
        data_out2 <= memory[A2];
    if (WE2)
        memory[A2] <= I2;
end

assign O1 = data_out1;
assign O2 = data_out2;

endmodule

