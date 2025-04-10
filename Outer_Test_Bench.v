`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2025 04:38:47 PM
// Design Name: 
// Module Name: Outer_Test_Bench
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


module Outer_Test_Bench(

    );
    
     // Inputs
    reg sysclk_p;
    reg sysclk_n;
    reg btnl;
    reg btnr;
    reg [7:0] switch;

    // Outputs
    wire [15:0] DQ;
    wire CS;
    wire RAS;
    wire CAS;
    wire WE;
    wire [14:0] Addr_out;
    wire [2:0] BA_out;
    wire LDM;
    wire UDM;
    wire [7:0] led;
    wire LDQS;
    wire LDQS_n;
//    wire UDQS;
    wire CKE;
    wire RESET;
    

    // Instantiate the Unit Under Test (UUT)
    OuterSource uut (
        .sysclk_p(sysclk_p),
        .sysclk_n(sysclk_n),
        .btnl(btnl),
        .btnr(btnr),
        .DQ(DQ),
        .CS(CS),
        .RAS(RAS),
        .CAS(CAS),
        .WE(WE),
        .Addr_out(Addr_out),
        .BA_out(BA_out),
        .LDM(LDM),
        .UDM(UDM),
        .led(led),
        .switch(switch),
        .LDQS(LDQS),
        .LDQS_n(LDQS_n),
//        .UDQS(UDQS),
        .CKE(CKE),
        .RESET_DRAM(RESET)
    );

    // Clock generation (simulate sysclk_p and sysclk_n)
    always begin
        sysclk_p = 0;
        sysclk_n = 1;
         #2.5;
        sysclk_p = 1;
        sysclk_n = 0; 
        #2.5;
    end

    // Stimuli process
    initial begin
        // Initialize Inputs      
        btnl = 0;
        btnr = 0;
        switch = 8'b10101010; // All switches are off

        // Apply reset at the start
        #1400;
        #500;

        // Test 1: Apply button presses and simulate behavior
        // Simulate button press on btnl
        btnl = 1;
        #200;
        btnl = 0;
        
        #100
        
        // Simulate button press on btnr
        btnr = 1;
        #100;
        btnr = 0;
        
        
        
        // End of simulation after a few clock cycles
        #6400000;

        $finish;
    end
    
    
    
endmodule
