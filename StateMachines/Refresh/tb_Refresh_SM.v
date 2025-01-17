`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2025 08:02:05 PM
// Design Name: 
// Module Name: tb_Refresh_SM
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


module tb_Refresh_SM;
    
    
    // Inputs
    reg clk;
    reg Refresh_Signal;

    // Outputs
    wire CS;
    wire RAS;
    wire CAS;
    wire WE;
    
    // Internal signals to monitor states
    wire [1:0] state;
    wire [1:0] next_state;
    
     // Instantiate the Unit Under Test (UUT)
    Refresh_SM uut (
        .CS(CS), 
        .RAS(RAS), 
        .CAS(CAS), 
        .WE(WE), 
        .clk(clk), 
 
        .Refresh_Signal(Refresh_Signal)
    );
    
    initial begin
        // Initialize Inputs
        clk = 0;
        Refresh_Signal = 0;

        // Wait for global reset
        #100;
        
        // Apply test vectors
        Refresh_Signal = 1; // Trigger refresh
        #50;
        Refresh_Signal = 0; // End refresh signal
        #200;
        
        // Add more test vectors as needed
        $finish;
    end
    
    always #5 clk = ~clk; //Generate clock with period of 10 time units

    // Monitor internal states
    initial begin
        $monitor("Time: %0t | State: %b | Next State: %b | CS: %b | RAS: %b | CAS: %b | WE: %b", 
                 $time, uut.state, uut.next_state, CS, RAS, CAS, WE);
    end

endmodule
