`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Keypad_tb
//////////////////////////////////////////////////////////////////////////////////
module Keypad_tb;
// Variables for testing the Keypad
logic clk;
logic [3:0] col;



logic [3:0] row;
logic [3:0] input_value;
logic [1:0] input_type;
logic new_input;
// Variables for the faking the keypad
logic key_down; // is it pressed down or not
logic [3:0] pressed_row; // the row to be read
logic [3:0] pressed_col; // the column to be outputed
// Instantiate the Keypad block with our variables (faster timing for the sim)
Keypad #(.CLOCK_PERIOD_NS(10), .KEY_TIME_NS(100), .OFF_TIME_NS(20),
.RELEASE_TIME_NS(200)) dut (
.clk(clk),
.col(col),
.row(row),
.input_value(input_value),
.input_type(input_type),
.new_input(new_input)
);
// The actual "press", allows us to time it with the row press perfectly
assign col = (key_down && (row & pressed_row) != 4'b0000) ? pressed_col :
4'b0000;
// Task for the key press emulator! Pretty neat, right?
task press_key(input [3:0] r, input [3:0] c);
begin
pressed_row = r;
pressed_col = c;
key_down = 1;
#1000;
key_down = 0;
#1000;
end
endtask
// 10 ns clock
initial clk = 0;
always #5 clk = ~clk;
initial begin
// Start: no key pressed, watch the rows scan
key_down = 0;
pressed_row = 4'b0000;
pressed_col = 4'b0000;
#1000;



// Press 1 (row 1, column 1) -> 1
press_key(4'b0001, 4'b0001);
// Press 5 (row 2, column 2) -> 5
press_key(4'b0010, 4'b0010);
// Press 9 (row 3, column 3) -> 9
press_key(4'b0100, 4'b0100);
// Press 0 (row 4, column 2) -> 0
press_key(4'b1000, 4'b0010);
// Press A (row 1, column 4) -> +
press_key(4'b0001, 4'b1000);
// Press # (row 4, column 3) -> =
press_key(4'b1000, 4'b0100);
// Press * (row 4, column 1) -> clear
press_key(4'b1000, 4'b0001);
// Hold D (row 4, column 4) -> /
press_key(4'b1000, 4'b1000);
$finish;
end
endmodule

