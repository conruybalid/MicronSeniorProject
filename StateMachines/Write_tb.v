`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 02:59:45 PM
// Design Name: 
// Module Name: Write_tb
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


module Write_tb;

    reg clk;
    reg areset;
    reg in;
    reg in_p; // in_p to decide if auto_precharge is chosen
    reg [14:0] Addr_Row;
    reg [9:0] Addr_Column;
    reg Addr_Column_11;
    reg A_10;
    reg A_12;
    reg [3:0] BA_in;
    reg [15:0] DQ_in;
    
    // Declare wires for monitoring output signals
    wire CS_n, RAS_n, CAS_n, WE_n;
    wire [14:0] Addr_out;
    wire [2:0] BA_out;
    wire LDM, UDM;
    wire [15:0] DQ_out;
    wire UDQS, LDQS;
    

    Write write_test (
        .clk(clk),
        .areset(areset),
        .in(in),
        .in_p(in_p),
        .Addr_Row(Addr_Row),
        .Addr_Column(Addr_Column),
        .Addr_Column_11(Addr_Column_11),
        .A_10(A_10),
        .A_12(A_12),
        .BA_in(BA_in),
        .DQ_in(DQ_in),
        .CS_n(CS_n),
        .RAS_n(RAS_n),
        .CAS_n(CAS_n),
        .WE_n(WE_n),
        .Addr_out(Addr_out),
        .BA_out(BA_out),
        .LDM(LDM),
        .UDM(UDM),
        .DQ_out(DQ_out),
        .UDQS(UDQS),
        .LDQS(LDQS)
    );
        

// Clock generation
    always #5 clk = ~clk; // Generate a clock with a period of 10ns

    initial begin
        // Initialize Inputs
        clk = 0;
        areset = 1;
        in = 0;
        in_p = 0;
        Addr_Row = 15'h0000;
        Addr_Column = 10'h000;
        Addr_Column_11 = 0;
        A_10 = 0;
        A_12 = 0;
        BA_in = 4'h0;
        DQ_in = 16'h0000;
        
        // Reset pulse
        #10 areset = 0;
        
        // Apply test case 1
        #10 in = 1;
            in_p = 1;
            Addr_Row = 15'h1A2B;
            Addr_Column = 10'h3C4;
            Addr_Column_11 = 1;
            A_10 = 1;
            A_12 = 0;
            BA_in = 4'h3;
            DQ_in = 16'hF00F;

        // Apply test case 2
        #20 in = 0;
            in_p = 0;
            Addr_Row = 15'h5D6E;
            Addr_Column = 10'h7F8;
            Addr_Column_11 = 0;
            A_10 = 0;
            A_12 = 1;
            BA_in = 4'h2;
            DQ_in = 16'hA5A5;
        
        // Finish simulation
        #50 $stop;
    end

endmodule
    