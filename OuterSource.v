`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 07:21:58 PM
// Design Name: 
// Module Name: OuterSource
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


module OuterSource(
    input wire sysclk_n, //
    input wire sysclk_p, //
    input wire btnl, //
    input wire btnr, //
    inout wire [15:0] DQ, //
    output wire CS, //
    output wire RAS, //
    output wire CAS, //
    output wire WE, //
    output wire [14:0] Addr_out, //
    output wire [2:0] BA_out, //
    output wire LDM, //
    output wire UDM, //
    output wire [7:0] led, 
    input wire [7:0] switch,
    inout wire LDQS,
    inout wire LDQS_n,
    inout wire UDQS,
    inout wire UDQS_n,
    
    output wire CK,
    output wire CK_n,
    output wire CKE,
    
    output wire RESET

    );    

    assign CKE = 1'b1;
    
    wire clk;
    wire ref;
    wire [5:0] state_out;
    
    wire clk_diff_pos;
    wire clk_diff_neg;
    
    
    IBUFGDS clk_inst (
        .O(clk),
        .I(sysclk_p),
        .IB(sysclk_n)
    );
    
     OBUFDS clkout_inst (
        .O(CK),   // Differential output positive
        .OB(CK_n),  // Differential output negative
        .I(clk)         // Single-ended input clock
    );
    

    
    assign clk_diff_pos = CK;
    assign clk_diff_neg = CK_n;
    
    
    Big_SM_Template SM (
        .CLK(clk),
        .diff_input_clk(clk_diff_pos),
        .diff_input_clk_neg(clk_diff_neg),
//        .RESET(RESET),
        .ZQCL(1'b1),
        .MRS(1'b0),
        .REF(ref),
//        .CKE(CKE),
        .ACT(1'b0),
        .WRITE(btnl),
        .READ(btnr),
//        .WRITE_AP(WRITE_AP),
//        .READ_AP(READ_AP),
//        .PRE(PRE),
        .Addr_Row(15'd5),
        .Addr_Column(10'd1),
        .Addr_Column_11(1'b1),
        .A_10(1'b0),
        .A_12(1'b1),
        .A13_14(2'b00),
        .BA_in(3'b101),
        .DQ(DQ[7:0]),
        .CS(CS),
        .RAS(RAS),
        .CAS(CAS),
        .WE(WE),
        .Addr_out(Addr_out),
        .BA_out(BA_out),
        .LDM(LDM),
        .UDM(UDM),
        .DQ_read(led[7:0]),
        .Data_input(switch),
        .LDQS(LDQS),
        .UDQS(UDQS),
        .LDQS_n(LDQS_n),
        .UDQS_n(UDQS_n),
        .RESET(RESET),
        
        .state(state_out)
    );
    
   

    reg [31:0] clk_count;
    
    initial begin
        clk_count <= 0;
    end
    
    always @(posedge clk) begin
        
        clk_count <= clk_count + 1;
   
        if (clk_count >= 32'd6400020)
        //if (clk_count >= 32'd600)
            clk_count <= 32'd0; 
    end
    
    assign ref = (clk_count >= 32'd6400000) ? 1'b1 : 1'b0;
    //assign ref = (clk_count >= 32'd550) ? 1'b1 : 1'b0;
   
    
//    assign led[0] = (state_out == 5'd4) ? 1'b1 : 1'b0;
    
    
    
    
    
endmodule
