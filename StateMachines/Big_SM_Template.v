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
    input [1:0] A13_14,
    input [2:0] BA_in,          // Activate | Write | Precharge (sometimes)
    inout wire [15:0] DQ,	//DQ line output and input for memory controller
    output reg CS,
    output reg RAS,
    output reg CAS,
    output reg WE,
    output reg [14:0] Addr_out, // Row or Column address depending on state
    output reg [2:0] BA_out,    // Bank address
    output reg LDM,             // Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg UDM,              // Upper 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg [15:0] DQ_read,   // 16 bit internal memory controller register name can change
    input [15:0] Data_input,
    output reg LDQS,            // Lower 8 bit data strobe
    output reg UDQS          // Upper 8 bit data strobe
//    output [2:0] BA,
//    output [15:0] A,
//    output BC,
//    output AP
    );
    
    // Hardcoded Inputs    
//    wire [2:0] BA_in;
//    assign BA_in = (BA_input === 3'bz) ? 3'b101 : BA_input;
//    wire [2:0] A13_14;
//    assign A13_14 = (A13_14_input === 2'bz) ? 2'b00 : A13_14_input;
//    wire [14:0] Addr_Row;
//    assign Addr_Row = (Addr_Row_input === 15'bz) ? 15'd1 : Addr_Row_input;
//    wire [9:0]  Addr_Column;
//    assign  Addr_Column = ( Addr_Column_input === 10'bz) ? 10'd1 :  Addr_Column_input;
//    wire Addr_Column_11;
//    assign  Addr_Column_11 = ( Addr_Column_11_input === 1'bz) ? 1'b1 :  Addr_Column_11_input;
//    wire A_10;
//    assign  A_10 = ( A_10_input === 1'bz) ? 1'b0 :  A_10_input;                                // Write - Precharge Y = 1 / N = 0  |  Precharge - One bank = 0 / All banks = 1
//    wire A_12;
//    assign  A_12 = ( A_12_input === 1'bz) ? 1'b1 :  A_12_input;                                // 1 = BL8 / 0 = BC4
    
    reg [5:0] state;
    reg [5:0] next_state;
    
    reg [31:0] ref_timer; // Assuming a 32-bit timer for simplicity
    reg [31:0] precharge_timer;
    reg [15:0] last_row_accessed;
    reg [3:0] Wait;
    reg [3:0] Strobe_num;
    
    reg DQ_dir;
    
    parameter IDLE = 2'b00, REFRESH = 2'b01, REF_WAIT = 2'b10;
    parameter tRFC = 32'd10; // Example refresh cycle time (103)
    parameter RL = 4'd5, WL = 4'd7;
    
    reg [3:0] RW_latency;
    
    
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
          Refresh_Wait = 5'd17,
          Strobe_Wait = 5'd18,
          Strobe = 5'd19;

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
            Strobe_Wait: state_name = "Strobe_Wait";
            Strobe: state_name = "Strobe";
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
        DQ_dir = 1'b0;
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
        
       if (next_state != Writing)
            DQ_dir = 1'b0;
       else
            DQ_dir = 1'b1; //make the DQ an input
            
        if (state == Strobe_Wait)
            Wait = Wait + 1;
        else 
            Wait = 0;
        
           
        if (state == Strobe)
            Strobe_num = Strobe_num + 1;
        else
            Strobe_num = 0;
        
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
                else if ((ACT || READ || WRITE) && !(MRS || REF))
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
//                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
//                    next_state = Writing;
//                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
//                    next_state = WritingAP;
//                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
//                    next_state = Reading;
//                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
//                    next_state = ReadingAP;
//                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
//                    next_state = Precharging;
//                else
//                    next_state = Bank_Active;
                  if (WRITE)
                    next_state = Writing;
                  else if (READ)
                    next_state = Reading;
                  else
                    next_state = Precharging;
            end
            
            Active_Power_Down: begin
                // Must work without clock
            end
            
            Writing: begin
//                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
//                    next_state = Writing;
//                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
//                    next_state = WritingAP;
//                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
//                    next_state = Reading;
//                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
//                    next_state = ReadingAP;
//                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
//                    next_state = Precharging;
//                else
                next_state = Strobe_Wait;
            end
            
            WritingAP: begin
                next_state = Precharging;
            end
            
            Reading: begin
//                if (WRITE && !(WRITE_AP || READ || READ_AP || PRE))
//                    next_state = Writing;
//                else if (WRITE_AP && !(WRITE || READ || READ_AP || PRE))
//                    next_state = WritingAP;
//                else if (READ && !(WRITE || WRITE_AP || READ_AP || PRE))
//                    next_state = Reading;
//                else if (READ_AP && !(WRITE || WRITE_AP || READ || PRE))
//                    next_state = ReadingAP;
//                else if (PRE && !(WRITE || WRITE_AP || READ || READ_AP))
//                    next_state = Precharging;
//                else
                next_state = Strobe_Wait;
            end
            
            ReadingAP: begin
                next_state = Precharging;
            end
            
             Strobe_Wait: begin
                if (Wait >= RW_latency -1)
                    next_state = Strobe;
                else
                    next_state = Strobe_Wait;
            end
           
            Strobe: begin
                if (Strobe_num == 5 -1)
                    next_state = Precharging;
                else
                    next_state = Strobe;
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
                LDQS = 1'bx;
                UDQS = 1'bx;	      
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
                Addr_out [14:13] = A13_14;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Write lower 8 bits
                UDM <= 1'b0;                        // Write lower 8 bits
                //DQ <= MCRegis;                    // 16 bit data line
//                UDQS <= CLK;
//                LDQS <= CLK;
                RW_latency <= 4'd7;
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
                Addr_out [14:13] = A13_14;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Read lower 8 bits
                UDM <= 1'b0;                        // Read lower 8 bits
                DQ_read <= DQ;                    // This needs to be changed
//                UDQS <= CLK;
//                LDQS <= CLK;
                RW_latency <= 4'd5;
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
                DQ_read <= DQ;                    
                
            end
            
            Strobe_Wait: begin
               
                RAS = 1'b1;
                CAS = 1'b1;     // all the address stuff for NOP command are V in the document
                WE = 1'b1;
               
                if (Wait == RW_latency -1) begin   // this is for one period of the clock the DQS is held low has to do with tRPRE
                    LDQS = 0;
                    UDQS = 0;
                end
            end
           
            Strobe: begin
                LDQS = CLK;
                UDQS = CLK;
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
                DQ_read = 16'bx;
                
                precharge_timer = 0;
            end

                
        endcase
            
    end
    
    // Tri-state buffer to control my_bus
    assign DQ = (DQ_dir) ? Data_input : 16'bz;
    
    
endmodule
