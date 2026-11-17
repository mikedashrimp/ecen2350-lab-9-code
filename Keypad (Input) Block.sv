`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 11:07:47 PM
// Design Name: 
// Module Name: Kaypad
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


//reference key for keypad

//        logic [3:0] row = {
//                4'b00, // R1
//                4'b01, // R2
//                4'b10, // R3
//                4'b11, // R4
//        }

//        logic [3:0] column = {
//                4'b00, // C1
//                4'b01, // C2
//                4'b10, // C3
//                4'b11, // C4
//        }
        
// logic [15:0] key_data [3:0] = {
//        4'b0000, // 0 key (R4 C2)
//        4'b0001, // 1 key (R1 C1)
//        4'b0010, // 2 key (R1 C2)
//        4'b0011, // 3 key (R2 C3)
//        4'b0100, // 4 key (R2 C1)
//        4'b0101, // 5 key (R2 C2)
//        4'b0110, // 6 key (R2 C3)
//        4'b0111, // 7 key (R3 C1)
//        4'b1000, // 8 key (R3 C2)
//        4'b1001, // 9 key (R3 C3)
//        4'b1010, // (R4 C1)
//        4'b1011, // (R4 C3)
//        4'b1100, // "+" key (R1 C4)
//        4'b1101, // "-" key (R2 C4)
//        4'b1110, // "*" key (R3 C4)
//        4'b1111, // "/" key (R4 C4)
// };

//delete below comments
// REWRITE: the keypad now does ALL of the input handling (scanning, debouncing, figuring out
// what kind of key it was) and hands the controller a clean one-clock "new_input" pulse.
// The controller no longer looks at the raw column pins at all.
//
// How it works:
//   1. Scan: drive R1..R4 one at a time (same rows / timing as before).
//   2. At the END of each row's time (so the column pins have settled), check the columns.
//      If one is high, save the key code + type and remember which row we were on.
//   3. send: pulse new_input for exactly one clock. key_data/data_type are already valid.
//   4. wait_release: keep driving the pressed key's row until its column has been 0 for 20 ms,
//      which debounces the release, so one press = one new_input.

module Keypad(
    input logic clk,
    input logic reset,
    input logic [3:0] column,

    output logic [3:0] row,
    output logic [3:0] key_data,  // held until the next key is pressed
    output logic [1:0] data_type, // 0 is number, 1 is operator, 2 is equals (#), 3 is clear (bottom-left *)
    output logic [0:0] new_input,  // high for one clock when a new key is ready
    
    //temp outputs for testing
    output logic [0:0] key_seen,
    output logic [20:0] release_cnt = 0,    // release timer (2,000,000 cycles = 20 ms)
    output logic [15:0] count = 0          // row timer (65,536 cycles = ~0.66 ms per row)

    );

    logic change_state;
    

    typedef enum logic [2:0] {
        R1_on,
        R2_on,
        R3_on,
        R4_on,
        send,          // pulse new_input (one clock)
        wait_release   // hold the key's row until it's been let go for 20 ms
    }row_state;

    row_state current_state, next_state;

    logic [3:0] row_hold;   // the row the pressed key is on
    logic [3:0] decoded;    // key code for the current row + column
    logic [1:0] decoded_type;

    initial begin
        current_state = R1_on;
        row_hold  = 4'b0000;
        key_data  = 4'b0000;
        data_type = 2'b00;
    end

    assign change_state = (count == 16'b1111111111111111);

    // Is a key on the current row pressed? Only checked at the end of the row's time.
    
    assign key_seen = 
//    1;
        (count == 16'b1111111111111111) && 
        (column != 4'b0000) && 
        (
        current_state == R1_on || current_state == R2_on ||
        current_state == R3_on || current_state == R4_on
        );

    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= R1_on;
            count <= 0;
            release_cnt <= 0;
        end
        else begin
            current_state <= next_state;

            // Row timer: restart whenever we change state
//            if (next_state != current_state)
//                count <= 0;
//            else
                count <= count + 1;

            // Save the key the moment we find it
            if (key_seen) begin
                key_data  <= decoded;
                data_type <= decoded_type;
                row_hold  <= row;
            end

            // Release timer: counts how long the column has been all 0s
            if (
//                current_state == wait_release && 
                column == 4'b0000)
                release_cnt <= release_cnt + 1;
            else
                release_cnt <= 0;
        end
    end

    always_ff @(posedge clk) begin
        next_state = current_state;
        case (current_state)
            R1_on : if (key_seen) next_state = send; else if (change_state) next_state = R2_on;
            R2_on : if (key_seen) next_state = send; else if (change_state) next_state = R3_on;
            R3_on : if (key_seen) next_state = send; else if (change_state) next_state = R4_on;
            R4_on : if (key_seen) next_state = send; else if (change_state) next_state = R1_on;
            send  : next_state = wait_release;
            wait_release : if (release_cnt == '1) next_state = R1_on;
            default : next_state = R1_on;
        endcase
    end

    // Outputs: which row to drive, and the new_input pulse
    always_comb begin
        new_input = 1'b0;
        case (current_state)
            R1_on : row = 4'b1000;
            R2_on : row = 4'b0100;
            R3_on : row = 4'b0010;
            R4_on : row = 4'b0001;
            send  : begin
                row = row_hold;
                new_input = 1'b1;
            end
            wait_release : row = row_hold;
            default : row = 4'b0000;
        endcase
    end

    // Decode: same key codes as before
    always_comb begin
        decoded = 4'b0000;
        case (current_state)
            R1_on : begin
                case (column)
                    4'b1000 : decoded = 4'b0001;  // 1
                    4'b0100 : decoded = 4'b0010;  // 2
                    4'b0010 : decoded = 4'b0011;  // 3
                    4'b0001 : decoded = 4'b1100;  // +
                    default : decoded = 4'b0000;
                endcase
            end
            R2_on : begin
                case (column)
                    4'b1000 : decoded = 4'b0100;  // 4
                    4'b0100 : decoded = 4'b0101;  // 5
                    4'b0010 : decoded = 4'b0110;  // 6
                    4'b0001 : decoded = 4'b1101;  // -
                    default : decoded = 4'b0000;
                endcase
            end
            R3_on : begin
                case (column)
                    4'b1000 : decoded = 4'b0111;  // 7
                    4'b0100 : decoded = 4'b1000;  // 8
                    4'b0010 : decoded = 4'b1001;  // 9
                    4'b0001 : decoded = 4'b1110;  // * "multipication"
                    default : decoded = 4'b0000;
                endcase
            end
            R4_on : begin
                case (column)
                    4'b1000 : decoded = 4'b1010;  // * "not multiplication" (clear)
                    4'b0100 : decoded = 4'b0000;  // 0
                    4'b0010 : decoded = 4'b1011;  // # (equals)
                    4'b0001 : decoded = 4'b1111;  // '/'
                    default : decoded = 4'b0000;
                endcase
            end
            default : decoded = 4'b0000;
        endcase

        // What kind of key is it?
        if (decoded <= 4'd9)           
            decoded_type = 2'b00; // number
        else if (decoded >= 4'b1100)   
            decoded_type = 2'b01; // operator
        else if (decoded == 4'b1011)   
            decoded_type = 2'b10; // equals
        else                           
            decoded_type = 2'b11; // clear (4'b1010)
    end
endmodule

