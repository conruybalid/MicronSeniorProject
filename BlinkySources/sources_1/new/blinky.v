`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2024 10:32:46 PM
// Design Name: 
// Module Name: blinky
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

//Connor was here
//Teehee
//BlinkBlink
module blinky(
    input clk_p,
    input clk_n,
    output [1:0] led
    );
    
    
    
    wire clk;
     
    IBUFGDS clk_inst (
        .O(clk),
        .I(clk_p),
        .IB(clk_n)
    );
    
    reg [24:0] count = 0;
 
    assign led[0] = count[24];
    assign led[1] = !led[0];
     
    always @ (posedge(clk)) count <= count + 1;
    
endmodule
