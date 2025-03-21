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
    input diff_input_clk,
    input diff_input_clk_neg,
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
    inout wire [7:0] DQ,	//DQ line output and input for memory controller
    output reg CS,
    output reg RAS,
    output reg CAS,
    output reg WE,
    output reg [14:0] Addr_out, // Row or Column address depending on state
    output reg [2:0] BA_out,    // Bank address
    output reg LDM,             // Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg UDM,              // Upper 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg [7:0] DQ_read,   // 16 bit internal memory controller register name can change
    input [7:0] Data_input,
    output wire LDQS,            // Lower 8 bit data strobe
    output wire LDQS_n,
    output wire UDQS,          // Upper 8 bit data strobe
    output wire UDQS_n,
//    output [2:0] BA,
//    output [15:0] A,
//    output BC,
//    output AP

    output reg RESET,

    
    output reg [5:0] state


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
    
    reg [5:0] next_state;
    
    reg [31:0] ref_timer; // Assuming a 32-bit timer for simplicity
    reg [31:0] precharge_timer;
    reg [31:0] activate_timer;
    reg [31:0] reset_timer;
    reg [15:0] last_row_accessed;
    reg [3:0] Wait;
    reg [3:0] Strobe_num;
    
    reg DQ_dir;
    
    parameter IDLE = 2'b00, REFRESH = 2'b01, REF_WAIT = 2'b10;
    parameter tRFC = 32'd103; // Example refresh cycle time (103)
    parameter tRCD= 32'd10;
    parameter RL = 4'd5, WL = 4'd7;
    
    reg [3:0] RW_latency;
    
    reg read_select;
    reg write_select;
    
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
    
    reg strobe_input;
    
    OBUFDS clkout_LDQS (
        .O(LDQS),   // Differential output positive
        .OB(LDQS_n),  // Differential output negative
        .I(strobe_input)         // Single-ended input clock
    );
    
//    OBUFDS clkout_UDQS (
//        .O(UDQS),   // Differential output positive
//        .OB(UDQS_n),  // Differential output negative
//        .I(strobe_input)         // Single-ended input clock
//    );
    
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
     
    reg read_strobe;
    reg [3:0] DQ_read_bit;
    
    wire clk_90;
    
    // Initialize state
    initial begin
        state = Power_On;
        next_state = Reset_Procedure;
        CS = 1'b0;
        RAS =1'b1;
        CAS = 1'b1;
        WE = 1'b1;
        DQ_dir = 1'b0;
        RESET = 1'b1;
        DQ_read_bit = 4'd0;
        //read_strobe = 1'b1;
    end
     
     
    // State Transition logic
    always @(posedge CLK) begin
        
        //Timer
        if (precharge_timer != 32'hFFFFFFFF) 
            precharge_timer = precharge_timer + 1;
        
       //Transition changes
       if (state == Reset_Procedure)
          reset_timer = reset_timer + 1;
       else
          reset_timer = 0;
       
       
       if (state == Refresh_Wait)
	       ref_timer = ref_timer + 1;
       else
	       ref_timer = 0;
        
       if (next_state == Idle)
            DQ_dir = 1'b0;
       else if (next_state == Writing)
            DQ_dir = 1'b1; //make the DQ an input
            
        if (state == Strobe_Wait)
            Wait = Wait + 1;
        else 
            Wait = 0;
        
           
        if (state == Strobe)
            Strobe_num = Strobe_num + 1;
        else
            Strobe_num = 0;
            
        if (state == Bank_Active)
            activate_timer = activate_timer + 1;
        else
            activate_timer = 0;
        
	   state <= next_state;

    end

    
    //next state logic
    
    always @(*) begin
 
        case (state)
            Power_On: begin
                next_state = Reset_Procedure;
            end
            
            Reset_Procedure: begin
                if (reset_timer < 32'd10)
                    next_state = Reset_Procedure;
                else
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
                if (MRS && !(REF))
                    next_state = Write_Leveling;
                else if (REF)// && !(MRS || ACT))
                    next_state = Refreshing;
                else if (( read_select || write_select) && !(MRS || REF))
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
                  if (activate_timer < tRCD)
                    next_state = Bank_Active;
                  else if (write_select)
                    next_state = Writing;
                  else if (read_select)
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
                if (Strobe_num == 9)
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
                RESET = 1'b0; //Keep RESET low for 100 ns
            end
            
            Initialization: begin
                RESET = 1'b1;

            end
            
            ZQ_Calibration: begin
            end
            
            Idle: begin
                CS = 1'b0;
                RAS =1'b1;
                CAS = 1'b1;
                WE = 1'b1;
                BA_out = 3'bx;
                strobe_input = 1'bx;
 	
//                LDQS = 1'bx;
//                UDQS = 1'bx;	
                
                read_select <= READ;
                write_select <= WRITE;
                      
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
//                CS = 1'b0;
//                RAS =1'b1; //why not 0?
//                CAS = 1'b1;
//                WE = 1'b1;		     
//                Addr_out <= 15'bx;
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
//                DQ_read <= 8'b00000000;
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
//                DQ_read <= DQ;                    // This needs to be changed
//                UDQS <= CLK;
//                LDQS <= CLK;
                RW_latency <= 4'd5;
            end
            
//           ReadingAP: begin
//                CS <= 1'b0;
//                RAS <= 1'b1;
//                CAS <= 1'b0;
//                WE <= 1'b1;
//                Addr_out [9:0] = Addr_Column;
//                Addr_out [10] = A_10;               // 1 =  precharge
//                Addr_out [11] = Addr_Column_11;     // Part of row addres
//                Addr_out [12] = A_12;               // 1 = BL8 / 0 = BC4
//                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
//                LDM <= 1'b0;                        // Read lower 8 bits
//                UDM <= 1'b0;                        // Read lower 8 bits
//                //DQ_read <= DQ;                    
                
//            end
            
            Strobe_Wait: begin
               
//                RAS = 1'b1;
//                CAS = 1'b1;     // all the address stuff for NOP command are V in the document
//                WE = 1'b1;
               
                if (Wait == RW_latency -1 && write_select) begin   // this is for one period of the clock the DQS is held low has to do with tRPRE
                    strobe_input = 0;
                end
            end
           
            Strobe: begin
//                LDQS = diff_input_clk;
//                LDQS_n = diff_input_clk_neg;
//                UDQS = diff_input_clk;
//                UDQS_n = diff_input_clk_neg;
                  if (write_select) begin
                      if (Strobe_num <= 5)
                        strobe_input = CLK;
                      else
                        strobe_input = 1'b0;
                  end
                  else if (read_select) begin
                      if (Strobe_num <= 3)
                        read_strobe = 1'b1;
                      else
                        read_strobe = 1'b0;
                  end
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
//                Addr_out [9:0] = 10'bx;
//                DQ_read = 16'bx;
                
                precharge_timer = 0;
            end

                
        endcase
            
    end
    
    // Tri-state buffer to control my_bus
    assign DQ[7:0] = (DQ_dir) ? Data_input : 8'bz;
    
    
   
    always @(clk_90) begin
        if (read_strobe) begin
             DQ_read_bit = DQ_read_bit + 1;
             case(DQ_read_bit)
                1: begin
                    DQ_read[0] <= DQ[0];
                end
                2: begin
                    DQ_read[1] <= DQ[1];
                end
                3: begin
                    DQ_read[2] <= DQ[2];
                end
                4: begin
                    DQ_read[3] <= DQ[3];
                end
                5: begin
                    DQ_read[4] <= DQ[4];
                end
                6: begin
                    DQ_read[5] <= DQ[5];
                end
                7: begin
                    DQ_read[6] <= DQ[6];
                end
                8: begin
                    DQ_read[7] <= DQ[7];
                end
                default: begin
                    DQ_read_bit = 0;
                end          
             endcase
        end
        else
            DQ_read_bit = 0;
                
    end
     
    phase_shifted_clock phaseShift (
        .clk_in(CLK),
        .rst(1'b0),
        .clk_out(clk_90)    
    );
    
endmodule


module phase_shifted_clock (
    input  wire clk_in,   // Input clock (e.g., 100 MHz)
    input  wire rst,      // Reset
    output wire clk_out,  // Phase-shifted clock output
    output reg  reg_value // Example register updating at clk_shifted
);

    wire clk_fb;       // Feedback clock for MMCM
    wire clk_shifted;  // 90-degree phase-shifted clock
    wire locked;       // MMCM lock signal

    // MMCM instantiation for Kintex-7
    MMCME2_BASE #(
        .CLKIN1_PERIOD(10.0),    // Adjust this to match your input clock period (100 MHz = 10.0 ns)
        .CLKFBOUT_MULT_F(10.0),  // Multiply input clock by 10
        .CLKOUT0_DIVIDE_F(10.0), // Divide output to match input frequency
        .CLKOUT0_PHASE(90.0)     // 90-degree phase shift
    ) mmcm_inst (
        .CLKIN1(clk_in),    // Input clock
        .CLKFBIN(clk_fb),   // Feedback
        .CLKFBOUT(clk_fb),  // Feedback output
        .CLKOUT0(clk_shifted), // Phase-shifted clock
        .LOCKED(locked),    // Locked signal
        .RST(rst)           // Reset input
    );

    // Register update at phase-shifted clock
    always @(posedge clk_shifted or posedge rst) begin
        if (rst)
            reg_value <= 0;
        else
            reg_value <= ~reg_value; // Example toggle
    end

    assign clk_out = clk_shifted; // Output the shifted clock

endmodule



