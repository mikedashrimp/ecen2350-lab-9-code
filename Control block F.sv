`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 12:38:58 AM
// Design Name: 
// Module Name: Control_block
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

module Calculator_top (
    input  logic clk,
    input  logic reset,
    input  logic [3:0] column,
    output logic [3:0] row,
    output logic [3:0] AN,
    output logic [7:0] SEG,
    output logic [1:0] out_type
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
    
//    logic signed [10:0] display_num;
    
//    always_ff @(posedge clk) begin
//        if (data_type == 2'b00) begin
//            if (a) begin
//                display_num = a;
//            end
//            else if (b) begin
//                display_num = b;
//            end
//        end
        
//        else if (data_type == 2'b10) begin
//            display_num = alu_result;
//        end
//        else if (data_type == 2'b01 || 2'b11) begin
//            display_num = 11'd0;
//        end
//    end

    // 1. Keypad Scanner
    Keypad keypad_unit (
        .clk(clk),
        .reset(reset),
        .column(column),
        .row(row),
        .key_data(key_data),
        .data_type(data_type),
        .new_input(new_input)  
    );

    // 2. Calculator Control FSM (translates key presses into memory control signals)
    Control_block ctrl_unit (
        .clk(clk),
        .reset(reset),
        .new_input(new_input),
        .data_type(data_type),
        .write(write),
        .address(address),
        .out_type(out_type)
//        .out(out) 
    );

    // 3. Memory / Registers (11-bit signed)
    memory_block #(
        .WIDTH(11)
    ) mem_unit (
        .clk(clk),
        .write(write),
        .address(address),
        .data(key_data),
        .ALU_result(alu_result), 
        .out_type(out_type),
        .a(a),
        .b(b),
        .op(op),
        .out(out)
    );

    // 4. Arithmetic Logic Unit (overridden to WIDTH = 11 to match memory & display)
    ALU_block #(
        .WIDTH(11)
    ) alu_unit (
        .a  (a),
        .b  (b),
        .x  (alu_result),
        .op (op)
    );

    // 5. 4-Digit 7-Segment Display Driver
    Display_block disp_unit (
        .clk(clk),
        .reset(reset),
//        .number(display_num),
        .number(out),
        .AN(AN),
        .SEG(SEG)
    );

endmodule


module Control_block (
    input  logic clk,
    input  logic reset,
    input  logic new_input,       // one-clock pulse from Keypad when a key is pressed
    input  logic [1:0] data_type, // 0 number, 1 operator, 2 equals, 3 clear
    output logic write,
    output logic [1:0] address,
    output logic [1:0] out_type
);

    typedef enum logic [1:0] {
        in_a,
        in_b,
        result
    } input_state;

    typedef enum logic [1:0] {
        NUMBER   = 2'b00,
        OPERATOR = 2'b01,
        EQUALS   = 2'b10,
        CLEAR    = 2'b11
    } key_type;

    input_state current_state, next_state;

    initial current_state = in_a; // known state at power-up

    // State register
    always_ff @(posedge clk) begin
        if (reset)
            current_state <= in_a;
        else
            current_state <= next_state;
    end

    // Next state logic: only moves when a new key comes in
    always_comb begin
        next_state = current_state;

        if (new_input) begin
            case (current_state)
                in_a : begin
                    if (data_type == OPERATOR) next_state = in_b;
                    // digits stay in in_a, equals is ignored, clear stays in in_a
                end
                in_b : begin
                    if (data_type == EQUALS)     next_state = result;
                    else if (data_type == CLEAR) next_state = in_a;
                    // digits stay in in_b, another operator just replaces the op
                end
                result : begin
                    if (data_type == CLEAR) next_state = in_a; // only clear gets us out
                end
                default : next_state = in_a;
            endcase
        end
    end

    // Output logic
    always_comb begin
        // Defaults: don't write anything
        write   = 1'b0;
        address = 2'b00;

        // What to display just depends on the state
        case (current_state)
            in_a   : out_type = 2'b00; // A
            in_b   : out_type = 2'b01; // B (shows 0 right after the operator, like a normal calculator)
            result : out_type = 2'b11; // result
            default: out_type = 2'b00;
        endcase

        if (reset) begin
            // Reset button also wipes A, B and op
            write   = 1'b1;
            address = 2'b11;
        end
        else if (new_input) begin
            // write is only high during the one-clock new_input pulse, so each key is written once.
            // key_data is already held steady by the keypad, so memory grabs the right value.
            if (data_type == CLEAR) begin
                write   = 1'b1;
                address = 2'b11; // clear (works from any state)
            end
            else begin
                case (current_state)
                    in_a : begin
                        if (data_type == NUMBER)   begin write = 1'b1; address = 2'b00; end // digit -> A
                        if (data_type == OPERATOR) begin write = 1'b1; address = 2'b10; end // op
                    end
                    in_b : begin
                        if (data_type == NUMBER)   begin write = 1'b1; address = 2'b01; end // digit -> B
                        if (data_type == OPERATOR) begin write = 1'b1; address = 2'b10; end // change op
                    end
                    default : ; // result: ignore everything except clear
                endcase
            end
        end
    end

endmodule
