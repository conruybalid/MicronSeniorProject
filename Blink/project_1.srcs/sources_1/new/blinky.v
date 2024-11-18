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


module blinky(
    input clk_p,
    input clk_n,
    output led
    );
    
    wire clk;
     
    IBUFGDS clk_inst (
        .O(clk),
        .I(clk_p),
        .IB(clk_n)
    );
    
endmodule
