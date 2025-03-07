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
    input wire sysclk_n,
    input wire sysclk_p,
    input wire btnl,
    input wire btnr,
    inout wire [15:0] DQ,
    output wire CS,
    output wire RAS,
    output wire CAS,
    output wire WE,
    output wire [14:0] Addr_out,
    output wire [2:0] BA_out,
    output wire LDM,
    output wire UDM,
    output wire [7:0] led,
    input wire [7:0] switch,
    inout wire LDQS,
    inout wire UDQS,
    
    output wire CK,
    output wire CK_n,
    output wire CKE

    );    

    assign CK = sysclk_p;
    assign CK_n = sysclk_n;
    assign CKE = 1'b1;
    
    Big_SM_Template SM (
        .CLK(sysclk_p),
//        .RESET(RESET),
        .ZQCL(1'b1),
//        .MRS(MRS),
//        .REF(REF),
//        .CKE(CKE),
//        .ACT(ACT),
        .WRITE(btnl),
        .READ(btnr),
//        .WRITE_AP(WRITE_AP),
//        .READ_AP(READ_AP),
//        .PRE(PRE),
        .Addr_Row(15'd1),
        .Addr_Column(10'd1),
        .Addr_Column_11(1'b1),
        .A_10(1'b0),
        .A_12(1'b1),
        .A13_14(2'b00),
        .BA_in(3'b101),
        .DQ(DQ),
        .CS(CS),
        .RAS(RAS),
        .CAS(CAS),
        .WE(WE),
        .Addr_out(Addr_out),
        .BA_out(BA_out),
        .LDM(LDM),
        .UDM(UDM),
        .DQ_read(led),
        .Data_input(switch),
        .LDQS(LDQS),
        .UDQS(UDQS)
    );
    

    
    
    
    
    
    
    
endmodule
