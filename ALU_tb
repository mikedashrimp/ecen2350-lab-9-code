`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2026 03:40:10 PM
// Design Name: 
// Module Name: ALU_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU_tb;

    parameter int WIDTH = 11;

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [WIDTH-1:0] x;
    logic [1:0] op;

     ALU_block dut (.a(a), .b(b), .op(op), .x(x));
     
     initial begin
        a = 1; b = 3; op = 2'b00;
        #1;
        a = 9; b = 4; op = 2'b01;
        #1;
        a = 5; b = 3; op = 2'b10;
        #1;
        a = 12; b = 3; op = 2'b11;
        #1;
        a = 1; b = 3; op = 2'b01;
        #1;
        $finish;    
    end
endmodule
