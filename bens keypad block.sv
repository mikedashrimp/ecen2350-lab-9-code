`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// The Input Unit
//////////////////////////////////////////////////////////////////////////////////
module Keypad #(
parameter int CLOCK_PERIOD_NS = 10, // 10 ns clock (100 MHz)
// Wait times in nanoseconds (so we can easily change it later)
parameter int KEY_TIME_NS = 250_000, // Time each row is driven before reading
the columns
parameter int OFF_TIME_NS = 1_000, // Down time between each row
parameter int RELEASE_TIME_NS = 20_000_000 // 20 whole ms of "no key" to
debounce the release
)(
input logic clk,
input logic [3:0] col,
output logic [3:0] row,
output logic [3:0] input_value,
output logic [1:0] input_type,
output logic new_input
);
// Stuff for the timing cycles to get the input working nice
localparam int CYCLES_KEY = KEY_TIME_NS / CLOCK_PERIOD_NS;
localparam int CYCLES_OFF = OFF_TIME_NS / CLOCK_PERIOD_NS;
localparam int CYCLES_RELEASE = RELEASE_TIME_NS / CLOCK_PERIOD_NS;
// The longest wait the timer ever has to count to
localparam int MAX_CYCLES = (CYCLES_RELEASE > CYCLES_KEY) ? CYCLES_RELEASE :
CYCLES_KEY;
// The states for the FSM
typedef enum logic [3:0] {
// ROW: Apply high to each of the 4 rows one at a time
S_ROW_0 = 4'b0000,
S_ROW_1 = 4'b0001,
S_ROW_2 = 4'b0010,
S_ROW_3 = 4'b0011,
// OFF: Wait for a little bit to prevent wrong registration of input
S_OFF_0 = 4'b0100,
S_OFF_1 = 4'b0101,
S_OFF_2 = 4'b0110,
S_OFF_3 = 4'b0111,


  // FOUND: We have found a new input! Save its decoded code (one clock)
S_FOUND = 4'b1000,
// SEND: The code is ready, pulse new_input for one clock
S_SEND = 4'b1010,
// RELEASE: Keep driving the same row until the column goes to 0 again
(button released)
S_RELEASE = 4'b1001
} state_t;
state_t current_state, next_state;
// Vars for the timing, basically how I'm counting how much time has passed
logic [$clog2(MAX_CYCLES+1)-1:0] timer_cnt; // $clog2(...) automatically finds
how many bits is needed!
logic time_expired; // Have we passed the amount that we are waiting?
// Saved copy of the row we drove and the columns we read
logic [3:0] row_temp;
logic [3:0] col_temp;
// Decoded version of row_temp/col_temp
logic [3:0] decoded_value;
logic [1:0] decoded_type;
// Zero everything out, and start FSM from the beginning
initial begin
current_state = S_ROW_0;
timer_cnt = '0;
row_temp = '0;
col_temp = '0;
input_value = '0;
input_type = '0;
end
// Figure out how long the current state lasts
always_comb begin
case (current_state)
S_ROW_0, S_ROW_1, S_ROW_2, S_ROW_3: time_expired = (timer_cnt >=
CYCLES_KEY - 1);
S_OFF_0, S_OFF_1, S_OFF_2, S_OFF_3: time_expired = (timer_cnt >=
CYCLES_OFF - 1);
default: time_expired = (timer_cnt >= CYCLES_RELEASE - 1);
endcase
end





// State register, do the state machine stuff and reset the count
always_ff @(posedge clk) begin
current_state <= next_state;
// Counter of the clock and restart whenever we change state
if (next_state != current_state || (current_state == S_RELEASE && col !=
4'b0000)) begin
timer_cnt <= '0; // Reset
end else begin
timer_cnt <= timer_cnt + 1'b1; // Increment
end
end
// Next state logic
always_comb begin
// Default: stay put
next_state = current_state;
case (current_state)
S_ROW_0: if (time_expired) begin
// Key in row 0 is pressed
if (col != 4'b0000) next_state = S_FOUND;
else next_state = S_OFF_0;
end
S_OFF_0: if (time_expired) next_state = S_ROW_1;
S_ROW_1: if (time_expired) begin
// Key in row 1 is pressed
if (col != 4'b0000) next_state = S_FOUND;
else next_state = S_OFF_1;
end
S_OFF_1: if (time_expired) next_state = S_ROW_2;
S_ROW_2: if (time_expired) begin
// A key in row 2 is pressed
if (col != 4'b0000) next_state = S_FOUND;
else next_state = S_OFF_2;
end
S_OFF_2: if (time_expired) next_state = S_ROW_3;
S_ROW_3: if (time_expired) begin
// A key in row 3 is pressed
if (col != 4'b0000) next_state = S_FOUND;
else next_state = S_OFF_3;
end
S_OFF_3: if (time_expired) next_state = S_ROW_0; // Loops around




S_FOUND: next_state = S_SEND; // No timer, use only one clock cycle
S_SEND: next_state = S_RELEASE; // No timer, use only one clock cycle
// Allows for both debouncing, AND waiting until the button is released
S_RELEASE: if (time_expired && col == 4'b0000) next_state = S_ROW_0;
default: next_state = S_ROW_0;
endcase
end
// Save a copy of the new inputs
always_ff @(posedge clk) begin
case (current_state)
S_ROW_0, S_ROW_1, S_ROW_2, S_ROW_3: begin
// Store the latest row checked and latest column input
row_temp <= row;
col_temp <= col;
end
S_FOUND: begin
// Hold the key's code until the next key is found
input_value <= decoded_value;
input_type <= decoded_type;
end
default: ; // Do nothing
endcase
end
// Output logic
always_comb begin
// Defaults (no row driven, no new input)
row = 4'b0000;
new_input = 1'b0;
case (current_state)
// Select which row to drive
S_ROW_0: row = 4'b0001;
S_ROW_1: row = 4'b0010;
S_ROW_2: row = 4'b0100;
S_ROW_3: row = 4'b1000;
// Keep driving the key's row while we save and send the key
S_FOUND: row = row_temp;
// Tell the controller a new key is ready (input_value is already valid
here)
S_SEND: begin




row = row_temp;
new_input = 1'b1;
end
// Keep driving the key's row so we can see when it's let go
S_RELEASE: row = row_temp;
default: ; // OFF states: keep the defaults
endcase
end
// Input decoding
always_comb begin
// Defaults
decoded_value = 4'b1011;
decoded_type = 2'b11;
case (row_temp)
4'b0001: begin
case (col_temp)
4'b0001: begin decoded_value = 4'b0001; decoded_type = 2'b00;
end // Key 1
4'b0010: begin decoded_value = 4'b0010; decoded_type = 2'b00;
end // Key 2
4'b0100: begin decoded_value = 4'b0011; decoded_type = 2'b00;
end // Key 3
4'b1000: begin decoded_value = 4'b1100; decoded_type = 2'b01;
end // Key +
default: ;
endcase
end
4'b0010: begin
case (col_temp)
4'b0001: begin decoded_value = 4'b0100; decoded_type = 2'b00;
end // Key 4
4'b0010: begin decoded_value = 4'b0101; decoded_type = 2'b00;
end // Key 5
4'b0100: begin decoded_value = 4'b0110; decoded_type = 2'b00;
end // Key 6
4'b1000: begin decoded_value = 4'b1101; decoded_type = 2'b01;
end // Key -
default: ;
endcase
end
4'b0100: begin
case (col_temp)
4'b0001: begin decoded_value = 4'b0111; decoded_type = 2'b00;



end // Key 7
4'b0010: begin decoded_value = 4'b1000; decoded_type = 2'b00;
end // Key 8
4'b0100: begin decoded_value = 4'b1001; decoded_type = 2'b00;
end // Key 9
4'b1000: begin decoded_value = 4'b1110; decoded_type = 2'b01;
end // Key *
default: ;
endcase
end
4'b1000: begin
case (col_temp)
4'b0001: begin decoded_value = 4'b1011; decoded_type = 2'b11;
end // Key CLEAR
4'b0010: begin decoded_value = 4'b0000; decoded_type = 2'b00;
end // Key 0
4'b0100: begin decoded_value = 4'b1010; decoded_type = 2'b10;
end // Key =
4'b1000: begin decoded_value = 4'b1111; decoded_type = 2'b01;
end // Key /
default: ;
endcase
end
default: ;
endcase
end
endmodule








