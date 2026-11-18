`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/17/2026 06:24:10 PM
// Design Name: 
// Module Name: keypad_display_test_block
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


module keypad_display_test_block(
    input  logic clk,
    input  logic reset,
    input  logic [3:0] column,
    output logic [3:0] row,
    output logic [3:0] AN,
    output logic [7:0] SEG
    );

    logic [3:0] key_data;
    logic [1:0] data_type;
    logic [1:0] address;
    logic new_input;
    logic write;
    
    logic signed [10:0] a;
    logic signed [10:0] b;
    logic signed [10:0] alu_result;
    logic signed [10:0] out;
    logic [1:0] op;


    
    Keypad keypad_unit (
        .clk(clk),
        .reset(reset),
        .column(column),
        .row(row),
        .key_data(key_data),
        .data_type(data_type),
        .new_input(new_input)  
    );
    
    always_comb begin
        write = new_input;
        case (data_type)
            2'b00 : address = 2'b00;
            2'b01 : address = 2'b10;
            2'b10 : address = 2'b11;
            default : begin
                address = 2'b00;
                write = 'b0;
            end
        endcase
    end
    
     memory_block #(
        .WIDTH(11)
    ) mem_unit (
        .clk(clk),
        .write(write),
        .address(address),
        .data(key_data),
        .ALU_result(alu_result), // FIX: port name was misspelled ".ALU_resul"
        .out_type(OUT_a),
        .a(a),
        .b(b),
        .op(op),
        .out(out)
    );
    
    Display_block disp_unit (
        .clk(clk),
        .reset(reset),
        .number(a),
        .AN(AN),
        .SEG(SEG)
    );
    
endmodule
