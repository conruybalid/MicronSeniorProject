`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2025 07:31:00 PM
// Design Name: 
// Module Name: Refresh_SM
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


module Refresh_SM(
    output reg CS,
    output reg RAS,
    output reg CAS,
    output reg WE,
    input clk,
    input Refresh_Signal
    );
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [31:0] timer; // Assuming a 32-bit timer for simplicity
    
    parameter IDLE = 2'b00, REFRESH = 2'b01, REF_WAIT = 2'b10;
    parameter tRFC = 32'd10; // Example refresh cycle time (103)
     
    // Initialize state
    initial begin
        state = IDLE;
        next_state = IDLE;
        timer = 0;
    end
     
     
    // State Transition logic
    always @(posedge clk) begin
	   state <= next_state;
	   if (state == REF_WAIT)
	       timer = timer + 1;
	   else
	       timer = 0;

    end

    
    //next state logic
    
    always @(*) begin
        case (state)
        
           IDLE: begin
               if (Refresh_Signal)
                   next_state = REFRESH;
               else
                   next_state = IDLE;
            end
            
            REFRESH: begin
                next_state = REF_WAIT;
                timer = 0;
            end
            
            REF_WAIT: begin
                if (timer < (tRFC - 1)) begin
                    next_state = REF_WAIT;
                end else if (Refresh_Signal)
                    next_state = REFRESH;
                else
                    next_state = IDLE;
                                     
            end
                    
        endcase
    end
    
    
    // State Actions
    
    always @(*) begin
    
        case (state)
            
            IDLE: begin
                CS = 1'b0;
                RAS =1'b1;
                CAS = 1'b1;
                WE = 1'b1;		      
            end
            
            REFRESH: begin
                CS = 1'b0;
                RAS = 1'b0;
                CAS = 1'b0;
                WE = 1'b1;
            end
            
            REF_WAIT: begin
                CS = 1'b0;
                RAS = 1'b1;
                CAS = 1'b1;
                WE = 1'b1;
            end
                
        endcase
            
    end
    
        
endmodule
