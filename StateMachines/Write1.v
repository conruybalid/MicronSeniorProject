`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2025 11:01:31 AM
// Design Name: 
// Module Name: Write1
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

module Write(
    input clk,
    input areset,               // Synchronous reset to state B
    input in,in_p,              // in_p to decide if auto_precharge is chosen
    input [14:0] Addr_Row,      // Used during Activate, open until next precharge
    input [9:0] Addr_Column,    // Used during Write
    input Addr_Column_11,       // A[11] Used during Write
    input A_10,                 // Write - Precharge Y = 1 / N = 0  |  Precharge - One bank = 0 / All banks = 1
    input A_12,                 // 1 = BL8 / 0 = BC4
    input [3:0] BA_in,          // Activate | Write | Precharge (sometimes)
    input [15:0] DQ_in,
    
    output reg CS_n,            // Chip select
    output reg RAS_n,           // Row Address Strobe
    output reg CAS_n,           // Column Address Strobe
    output reg WE_n,            // Write Enable
    output reg CKE,             // Needs to be high during all these commands
    output reg [14:0] Addr_out, // Row or Column address depending on state
    output reg [2:0] BA_out,    // Bank address
    output reg LDM,             // Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg UDM,             // Upper 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg ODT,             // On-die termination, 
    output reg ZQ,              // External reference for chip, don't think we need to adjust
    output reg RESET_n,         // Reset, only restriction is make sure CKE is low before going high again
    output reg CK,              // Clock positive edge
    output reg CK_n,            // Clock negative edge
    output reg [15:0] DQ_out,   // 16 bit data line
    output reg LDQS,            // Lower 8 bit data strobe
    output reg LDQS_n,          // Lower 8 bit negative_edge data strobe
    output reg UDQS,            // Upper 8 bit data strobe
    output reg UDQS_n           // Upper 8 bit negative_edge data strobe
    );
    
    parameter Activate = 0, Writing = 1, Writing_AP = 2, Precharge = 3;  // States
    
    reg [2:0] present_state, next_state;

    always @(posedge clk) begin
        case (present_state)
            Activate: next_state = (in == 0 ? (in_p == 0 ? Writing : Writing_AP) : Precharge); // If in == 0, in2 == 0 transitions to Writing, in2 == 1 transitions to Writing_AP, if in == 1, transition to Precharge
            Writing: next_state = (in == 0 ? (in_p == 0 ? Writing : Writing_AP) : Precharge); // If in == 0, in2 == 0 transitions to Writing, in2 == 1 transitions to Writing_AP, if in == 1, transition to Precharge
            Writing_AP: next_state = Precharge;
            Precharge: next_state = Activate; // Should go to an idle state after activate 
        endcase
    end
    
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            present_state <= Activate;
        end else begin
            present_state <= next_state;
        end
    end
    
    always @(*) begin
        case (present_state)
                      
            Activate: begin
                CS_n <= 1'b0;
                RAS_n <= 1'b0;                      // Low = choose Row
                CAS_n <= 1'b1;
                WE_n <= 1'b1;
                Addr_out <= Addr_Row;               // 15 bit hex value, start at 15'h1
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b1;                        // Ignore lower 8 bits
                UDM <= 1'b1;                        // Ignore lower 8 bits
                
            end
            
            Writing: begin
                CS_n <= 1'b0;
                RAS_n <= 1'b1;
                CAS_n <= 1'b0;                      // Low = Choose Column
                WE_n <= 1'b0;
                Addr_out [9:0] = Addr_Column;
                Addr_out [10] = A_10;               // 0 = no precharge
                Addr_out [11] = Addr_Column_11;
                Addr_out [12] = A_12;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Write lower 8 bits
                UDM <= 1'b0;                        // Write lower 8 bits
                DQ_out <= DQ_in;                    // 16 bit data line
                UDQS <= clk;
                LDQS <= clk;
            end
            
            Writing_AP: begin
                CS_n <= 1'b0;
                RAS_n <= 1'b1;
                CAS_n <= 1'b0;
                WE_n <= 1'b0;
                Addr_out [9:0] = Addr_Column;
                Addr_out [10] = A_10;               // 1 =  precharge
                Addr_out [11] = Addr_Column_11;     // Part of row addres
                Addr_out [12] = A_12;               // 1 = BL8 / 0 = BC4
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Write lower 8 bits
                UDM <= 1'b0;                        // Write lower 8 bits
                DQ_out <= DQ_in;
                
            end            
            
            Precharge: begin
                CS_n <= 1'b0;
                RAS_n <= 1'b0;
                CAS_n <= 1'b1;
                WE_n <= 1'b0;
                Addr_out [10] = A_10;               // 1 =  one bank / 0 = all banks
                Addr_out [11] = Addr_Column_11;     // Does not matter
                Addr_out [12] = A_12;               // Does not matter
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0 / Does not matter IF A_10 == 0
                LDM <= 1'b1;                        // Ignore lower 8 bits
                UDM <= 1'b1;                        // Ignore lower 8 bits
            end
        endcase
    end
    
endmodule
