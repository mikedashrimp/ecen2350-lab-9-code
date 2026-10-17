# ecen2350-lab-9-code


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
    
    input wire clk,
    input wire reset_n
    );
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
        
        end
        
        else begin
            case (a)
                
                
                default : ;
            endcase
        
            case (b)
                
                
                default : ;
            endcase
            
            case (op)
                
                
                default : ;
            endcase
            
            case (ALUx)
                
                
                default : ;
            endcase
        end
    end
endmodule
