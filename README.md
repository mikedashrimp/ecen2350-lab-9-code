# ecen2350-lab-9-code

```
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 02:34:29 AM
// Design Name: 
// Module Name: memory inputs
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


module memory_inputs(
    inout logic [10:0] a,
    inout logic [10:0] b,
    inout logic [1:0] op,
    inout logic [10:0] ALUx,
    
    input logic clk, reset,

    logic [10:0] mem_array [0:3] = '{4{11'b00000000000}};
    );

typedef enum logic [1:0] {
    //add state stuff
    WAIT,
    INPUT_a,
    INPUT_b,
    INPUT_op
    INPUT_ALUx
}state_t;

state_t state = INPUT_a;
state_t next_state;

    always_ff @(posedge clk) begin   //more state stuff
        if (reset || state == WAIT)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always_ff @(posedge clk) begin   //more state stuff
        state <= next_state;
    end


    always_comb begin
        //only one case statement, using the state stuff defined above
        case (state)
            INPUT_a:
                if (reset)
                    next_state = WAIT;
                else if (a)
                    a_count = 0;
                    a_val = 0;
                    while (count == 2 || !op)
                        a_val= (a_val*10) + a;
                            //array stuff
                        mem_array[0] = a_val;

                        next_state = INPUT_a;
                        count++;
                    end
                    next_state = INPUT_op       

                else if (op)
                    next_state = INPUT_op
                    
            INPUT_b:
                if (reset)
                    next_state = WAIT;
                else if (b)
                    b_count = 0;
                    b_val = 0;
                    while (count < 3 || b)
                        b_val= (b_val*10) + a;
                            //array stuff
                        mem_array[1] = b_val;

                        next_state = INPUT_b;
                        count++;
                    end

                else if (ALUx)
                    next_state = INPUT_ALUx;
                
            INPUT_op:
                if (reset)
                    next_state = WAIT;
                else if (op)
                    op_val = op;
                    mem_array[2] = op_val;
                    //array stuff

                    next_state = INPUT_b;


                else if (b)
                    next_state = INPUT_b;

            INPUT_ALUx:
                if (reset)
                    next_state = WAIT;

                else if (ALUx)
                    ALUx_val = ALUx;
                    mem_array[4] = ALUx_val;

                    next_state = WAIT;

            default:
                next_state = WAIT;
        endcase
    
    end
endmodule
