`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 11:58:26 AM
// Design Name: 
// Module Name: Big_SM_Template
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


module Big_SM_Template(
    input CLK,
    input RESET,
    input ZQCL,
    input MRS,
    input REF,
    input CKE,
    input ACT,
    input WRITE,
    input READ,
    input WRITE_AP,
    input READ_AP,
    input PRE,
    input [14:0] Addr_Row,      // Used during Activate, open until next precharge
    input [9:0] Addr_Column,    // Used during Write
    input Addr_Column_11,       // A[11] Used during Write
    input A_10,                 // Write - Precharge Y = 1 / N = 0  |  Precharge - One bank = 0 / All banks = 1
    input A_12,                 // 1 = BL8 / 0 = BC4
    input [3:0] BA_in,          // Activate | Write | Precharge (sometimes)
    input [15:0] DQ_in,
    output reg CS,
    output reg RAS,
    output reg CAS,
    output reg WE,
    output reg [14:0] Addr_out, // Row or Column address depending on state
    output reg [2:0] BA_out,    // Bank address
    output reg LDM,             // Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg UDM,              // Upper 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg [15:0] DQ_out,   // 16 bit data line
    output reg LDQS,            // Lower 8 bit data strobe
    output reg UDQS          // Upper 8 bit data strobe
//    output [2:0] BA,
//    output [15:0] A,
//    output BC,
//    output AP
    );
    
    reg [5:0] state;
    reg [5:0] next_state;
    
    reg [31:0] ref_timer; // Assuming a 32-bit timer for simplicity
    reg [31:0] precharge_timer;
    reg [15:0] last_row_accessed;
    
    parameter IDLE = 2'b00, REFRESH = 2'b01, REF_WAIT = 2'b10;
    parameter tRFC = 32'd10; // Example refresh cycle time (103)
    
parameter Power_On = 5'd0,
          Reset_Procedure = 5'd1,
          Initialization = 5'd2,
          ZQ_Calibration = 5'd3,
          Idle = 5'd4,
          Write_Leveling = 5'd5,
          Self_Refresh = 5'd6,
          Refreshing = 5'd7,
          Precharge_Power_Down = 5'd8,
          Activating = 5'd9,
          Bank_Active = 5'd10,
          Active_Power_Down = 5'd11,
          Writing = 5'd12,
          WritingAP = 5'd13,
          Reading = 5'd14,
          ReadingAP = 5'd15,
          Precharging = 5'd16,
          Refresh_Wait = 5'd17;

    reg [8*20:1] state_name; // 20-character string
    
    always @(*) begin
        case (state)
            Power_On: state_name = "Power_On";
            Reset_Procedure: state_name = "Reset_Procedure";
            Initialization: state_name = "Initialization";
            ZQ_Calibration: state_name = "ZQ_Calibration";
            Idle: state_name = "Idle";
            Refreshing: state_name = "Refreshing";
            Activating: state_name = "Activating";
            Bank_Active: state_name = "Bank_Active";
            Writing: state_name = "Writing";
            WritingAP: state_name = "WritingAP";
            Reading: state_name = "Reading";
            ReadingAP: state_name = "ReadingAP";
            Precharging: state_name = "Precharging";
            Refresh_Wait: state_name = "Refresh_Wait";
            default: state_name = "Unknown";
        endcase
    end
     
    // Initialize state
    initial begin
        state = Power_On;
        next_state = Reset_Procedure;
        CS = 1'b0;
        RAS =1'b1;
        CAS = 1'b1;
        WE = 1'b1;
    end
     
     
    // State Transition logic
    always @(posedge CLK) begin
        
        //Timer
        if (precharge_timer != 32'hFFFFFFFF) 
            precharge_timer = precharge_timer + 1;
        
       //Transition changes
       if (state == Refresh_Wait)
	       ref_timer = ref_timer + 1;
       else
	       ref_timer = 0;
        
	   state <= next_state;

    end

    
    //next state logic
    
    always @(*) begin
 
        case (state)
            Power_On: begin
                next_state = Reset_Procedure;
            end
            
            Reset_Procedure: begin
                next_state = Initialization;
            end
            
            Initialization: begin
                if (ZQCL)
                    next_state = ZQ_Calibration;
                else
                    next_state = Initialization;
            end
            
            ZQ_Calibration: begin
                next_state = Idle;
            end
            
            Idle: begin
                if (MRS && !(REF || ACT))
                    next_state = Write_Leveling;
                else if (REF && !(MRS || ACT))
                    next_state = Refreshing;
                else if (ACT && !(MRS || REF))
                    next_state = Activating;
                else
                    next_state = Idle;
                    
            end
            
            Write_Leveling: begin
                next_state = Idle;
            end
            
            Self_Refresh: begin
                // Hmm, this one needs to work without the clock running
            end
            
            Refreshing: begin
                next_state = Refresh_Wait;
            end
            
            Refresh_Wait: begin
                if (ref_timer < (tRFC - 1)) begin
                    next_state = Refresh_Wait;
                end else if (REF)
                    next_state = Refreshing;
                else
                    next_state = Idle;
                                     
            end
            
            
            Precharge_Power_Down: begin
                // Hmm, this one needs to work without the clock running
            end
            
            Activating: begin
                next_state = Bank_Active;
            end
            
            Bank_Active: begin
                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
                    next_state = Writing;
                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
                    next_state = WritingAP;
                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
                    next_state = Reading;
                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
                    next_state = ReadingAP;
                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
                    next_state = Precharging;
                else
                    next_state = Bank_Active;
            end
            
            Active_Power_Down: begin
                // Must work without clock
            end
            
            Writing: begin
                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
                    next_state = Writing;
                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
                    next_state = WritingAP;
                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
                    next_state = Reading;
                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
                    next_state = ReadingAP;
                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
                    next_state = Precharging;
                else
                    next_state = Bank_Active;
            end
            
            WritingAP: begin
                next_state = Precharging;
            end
            
            Reading: begin
                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
                    next_state = Writing;
                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
                    next_state = WritingAP;
                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
                    next_state = Reading;
                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
                    next_state = ReadingAP;
                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
                    next_state = Precharging;
                else
                    next_state = Bank_Active;
            end
            
            ReadingAP: begin
                next_state = Precharging;
            end
            
            Precharging: begin
                next_state = Idle;
            end
                    
        endcase
    end
    
    
    // State Actions
    
    always @(*) begin
    
        case (state)
            
            Power_On: begin
            end
            
            Reset_Procedure: begin
            end
            
            Initialization: begin
            end
            
            ZQ_Calibration: begin
            end
            
            Idle: begin
                CS = 1'b0;
                RAS =1'b1;
                CAS = 1'b1;
                WE = 1'b1;
                BA_out = 3'bx;		      
            end
            
            Write_Leveling: begin
            end
            
            Self_Refresh: begin
            end
            
            Refreshing: begin
                CS = 1'b0;
                RAS = 1'b0;
                CAS = 1'b0;
                WE = 1'b1;
            end
            
            Refresh_Wait: begin
                CS = 1'b0;
                RAS = 1'b1;
                CAS = 1'b1;
                WE = 1'b1;
            end
            
            Precharge_Power_Down: begin
            end
            
            Activating: begin
                CS <= 1'b0;
                RAS <= 1'b0;                      // Low = choose Row
                CAS <= 1'b1;
                WE <= 1'b1;
                Addr_out <= Addr_Row;               // 15 bit hex value, start at 15'h1
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b1;                        // Ignore lower 8 bits
                UDM <= 1'b1;                        // Ignore lower 8 bits
            end
            
            Bank_Active: begin
                CS = 1'b0;
                RAS =1'b1;
                CAS = 1'b1;
                WE = 1'b1;		     
                Addr_out <= 15'bx;
            end
            
            Active_Power_Down: begin
            end
            
            Writing: begin
                CS <= 1'b0;
                RAS <= 1'b1;
                CAS <= 1'b0;                      // Low = Choose Column
                WE <= 1'b0;
                Addr_out [9:0] = Addr_Column;
                Addr_out [10] = A_10;               // 0 = no precharge
                Addr_out [11] = Addr_Column_11;
                Addr_out [12] = A_12;
                Addr_out [14:13] = 2'b00;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Write lower 8 bits
                UDM <= 1'b0;                        // Write lower 8 bits
                DQ_out <= DQ_in;                    // 16 bit data line
                UDQS <= CLK;
                LDQS <= CLK;
            end
            
            WritingAP: begin
            end
            
            Reading: begin
                CS <= 1'b0;
                RAS <= 1'b1;
                CAS <= 1'b0;                      // Low = Choose Column
                WE <= 1'b1;
                Addr_out [9:0] = Addr_Column;
                Addr_out [10] = A_10;               // 0 = no precharge
                Addr_out [11] = Addr_Column_11;
                Addr_out [12] = A_12;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Read lower 8 bits
                UDM <= 1'b0;                        // Read lower 8 bits
                DQ_out <= DQ_in;                    // This needs to be changed
                UDQS <= CLK;
                LDQS <= CLK;
            end
            
            ReadingAP: begin
                CS <= 1'b0;
                RAS <= 1'b1;
                CAS <= 1'b0;
                WE <= 1'b1;
                Addr_out [9:0] = Addr_Column;
                Addr_out [10] = A_10;               // 1 =  precharge
                Addr_out [11] = Addr_Column_11;     // Part of row addres
                Addr_out [12] = A_12;               // 1 = BL8 / 0 = BC4
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Read lower 8 bits
                UDM <= 1'b0;                        // Read lower 8 bits
                DQ_out <= DQ_in;                    // needs to be changed 
                
            end            
            
            Precharging: begin
                CS <= 1'b0;
                RAS <= 1'b0;
                CAS <= 1'b1;
                WE <= 1'b0;
                Addr_out [10] = A_10;               // 1 =  one bank / 0 = all banks
                Addr_out [11] = Addr_Column_11;     // Does not matter
                Addr_out [12] = A_12;               // Does not matter
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0 / Does not matter IF A_10 == 0
                LDM <= 1'b1;                        // Ignore lower 8 bits
                UDM <= 1'b1; 
                
                //For showcasing
                Addr_out [9:0] = 10'bx;
                DQ_out = 16'bx;
                
                precharge_timer = 0;
            end

                
        endcase
            
    end
    

    
    
endmodule
