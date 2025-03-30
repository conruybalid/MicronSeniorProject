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

// Input vs output can be confusing
// Inputs come from our Outer source, where we can specify addresses and data to write etc
// Outputs leave this state machine, pass through our Outer Source, and are then inputs to the DRAM and LEDs
// DQ is an exception. It is inout as we both Write and Read data from the same pins
module Big_SM_Template(
    input wire CLK,                  // 320 MHz / 3.1 ns
    input wire Reset_input,          // Reset command, issued by pressing top button
    input wire ZQCL,                 // ZQ Calibration - Set high
    input wire MRS,                  // Mode Registers - Set low
    input wire REF,                  // Refresh - Every 64 ms
    input wire CKE,                  // Clock Enable - Should be set high for most states ***not currently using!!!*** should probably be an output
    input wire ACT,                  // Activate state - No longer used, as we have write or read commands automatically activate
    input wire WRITE,                // Write command - Controlled by left button
    input wire READ,                 // Read command - Controlled by right button
    input wire PRE,                  // Not currently using, could probably get rid of?
    input wire [14:0] Addr_Row,      // Used during Activate state, open until next precharge
    input wire [9:0] Addr_Column,    // Used during Write and Read states
    input wire A_10,                 // Write & Read - Precharge Y = 1 / N = 0  |  Precharge - One bank = 0 / All banks = 1
    input wire A_11,                 // Write & Read - Additional column address
    input wire A_12,                 // Write & Read - 1 = BL8 (Burst Length 8 bits) / 0 = BC4 (Burst Chop 4 bits)
    input wire [1:0] A13_14,         // Write & Read - Unnecessary bits
    input wire [2:0] BA_in,          // Activate | Write | Precharge (sometimes) - Bank Address
    input wire [7:0] Data_Write,     // Write - 1 byte is writen from our development board switches to the DQ line 
    inout wire [7:0] DQ,	         // Data line connecting between memory controller and DRAM
    inout wire LDQS,                 // Write & Read - Lower 8 bit data strobe, oscillates at each bit we read or write
    inout wire LDQS_n,               // Differential pair to LDQS
    inout wire UDQS,                 // Write & Read - Upper 8 bit data strobe, oscillates at each bit we read or write
    inout wire UDQS_n,               // Differential pair to UDQ
    output reg [7:0] Data_read,      // Read - 1 byte from DQ is read to this reg. It is then outputted to our LEDs
    output reg CS,                   // Active Low - Chip select - Used to select state - Almost always active
    output reg RAS,                  // Active Low - Row Address Strobe - Used to select state - Active in Refresh / Precharge / Activate
    output reg CAS,                  // Active Low - Column Address Strobe  - Used to select state - Active in Refresh / Write / Read
    output reg WE,                   // Active Low - Write Enable - Used to select state - Active in Precharge / Write
    output reg RESET_Output,         // Reset (Reset command to DRAM Reset pin)
    output reg [14:0] Addr_out,      // Row or Column address depending on state
    output reg [2:0] BA_out,         // Bank address
    output reg LDM,                  // Write - Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output reg UDM,                 // Write - Uppder 8 bit data mask - Write = 0 / Ignore (mask) data = 1

    output reg [5:0] state           // Output current state, currently used during testing
    );
    
   wire clk_90;                      // Phase-shifted clock by 90 degrees. This allows reading DQS between rising and falling edges of clk_in
   
    reg [5:0] next_state;            // Used to select states in state machine
    
    reg [31:0] tRFC_timer;            // Refresh timer - Used to wait tRFC after refresh command before any other action
    reg [31:0] precharge_timer;      // (not used right now) This keeps track of the last time we did a precharge. 
                                     // tRP - minimum time between precharge and next activate
    reg [31:0] activate_timer;       // time between activate and read/write command.
                                    // tRCD - row to column delay
    reg [31:0] reset_timer;         // timer used for holding RESET pin low for 100 ns
                                    // tRST = reset hold time
    reg [15:0] last_row_accessed;    // Not currently being used
    reg [3:0] RL_WL_count;          // Used for Strobing DQS - wait RL or WL
                                    // RL/WL = read/write latency
    reg [3:0] Strobe_count;         // Used for Strobing DQS - counting how many clock cycles we have been in the strobe state
                                    // 5 strobes are needed for a write
    parameter tWR = 32'd5;           // wait tWR (write recovery) after before precharging
                                    // tBURST
     
    
    reg DQ_dir;                      // DQ Direction - Chooses whether DQ line is Writing or Reading
    
    
    parameter tRFC = 32'd90;       // Refresh Cycle Time (90) min of 280 ns at 3.1 ns per period
    parameter tRCD= 32'd5;         // Row to Column Delay 15+ ns at 3.1 ns per period
    parameter RL = 4'd5;            // Read Latency = Additive Latency (AL, which is 0 based on timing diagrams) + CAS Latency (CL)
    parameter WL = 4'd5;            //Write Latency = Additive Latency (AL, which is 0 based on timing diagrams) + CAS Write Latency (CWL)
                                    // to be used with RL_WL_count
    
    
    
    reg [3:0] RL_WL_MAXVALUE;            // Used for Strobing DQS - Read Write Latency - get assigned RL or WL
    reg write_select;                // Select Write SM route - Gets set by WRITE command. Holds until back to idle
    reg read_select;                 // Select Read SM route - Gets set by READ command. Holds until back to idle
    
    reg read_DQS_from_DRAM;                 // Used for strobing
    reg [3:0] DQ_read_bitline;           // which DQ line are we reading
    
    reg write_DQS_to_DRAM;                // Used for strobing
    
    // Assign decimal values different states
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

    reg [8*20:1] state_name;                // 20-character string
    
    
    
    // Create differential DQS from strobe input clock (DRAM requires differential strobe vs only positive)
    OBUFDS clkout_LDQS (
        .O(LDQS),                           // Differential output positive
        .OB(LDQS_n),                        // Differential output negative
        .I(write_DQS_to_DRAM)                    // Single-ended input clock
    );
    
//    OBUFDS clkout_UDQS (
//        .O(UDQS),   // Differential output positive
//        .OB(UDQS_n),  // Differential output negative
//        .I(write_DQS_to_DRAM)         // Single-ended input clock
//    );
    
    // Assign names to states, useful for simulation
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
        RESET_Output = 1'b1;
        DQ_read_bitline = 4'd0;
    end
     
     
    // Refreshing and strobng 
    // Add something about what this always block does, then comments bove each if statement
    always @(posedge CLK) begin
        
        //(not currently used) Precharge_Timer that keeps track of the last time we were in the precharge state
        // May need to wait to read or write after precharge
        if (precharge_timer != 32'hFFFFFFFF) 
            precharge_timer = precharge_timer + 1;
        
       //Mealy Actions
       
       //Increment reset timer - wait 100 ns with reset pin low
       if (state == Reset_Procedure)
          reset_timer = reset_timer + 1;
       else
          reset_timer = 0;
       
       // Increment refresh wait timer - wait tRFC
       if (state == Refresh_Wait)
	       tRFC_timer = tRFC_timer + 1;
       else
	       tRFC_timer = 0;
	       
      // Comment
       if (next_state == Idle)
            DQ_dir = 1'b0;
       else if (next_state == Writing)
            DQ_dir = 1'b1; //make the DQ an input
            
            // Comment
        if (state == Strobe_Wait)
            RL_WL_count = RL_WL_count + 1;
        else 
            RL_WL_count = 0;
        
              // Comment
        if (state == Strobe)
            Strobe_count = Strobe_count + 1;
        else
            Strobe_count = 0;
            
            
              // Comment    
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
                if (reset_timer < 32'd33) // Hold RESET pin for 100 ns (3.1 ns * 33 = 102.3)   
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
            
            // Idle state is where we stay after powerup unless we Write, Read, or Refresh
            Idle: begin
                if (MRS && !(REF))
                    next_state = Write_Leveling;
                else if (REF)// && !(MRS || ACT))
                    next_state = Refreshing;
                else if (( read_select || write_select) && !(MRS || REF))
                    next_state = Activating;
                else if (Reset_input)
                    next_state = Reset_Procedure;
                else
                    next_state = Idle;
            end
            
//            Write_Leveling: begin
//                next_state = Idle;
//            end
            
//            Self_Refresh: begin
//                // Hmm, this one needs to work without the clock running
//            end
            
            Refreshing: begin
                next_state = Refresh_Wait;
            end
            
            
            // refresh wait next_state logic
            Refresh_Wait: begin
                if (tRFC_timer < (tRFC - 1)) begin //If not waited tRFC, continue waiting
                    next_state = Refresh_Wait;
                end else if (REF) // If tRFC is reached and REF signal is still active, refresh again (back to back refresh)
                    next_state = Refreshing;
                else //tRFC is reached and REF signal is low, go back to idle
                    next_state = Idle;
                                     
            end
            
            
//            Precharge_Power_Down: begin
//                // Hmm, this one needs to work without the clock running
//            end
            
            Activating: begin
                next_state = Bank_Active;
            end
            
            Bank_Active: begin
                  if (activate_timer < tRCD)
                    next_state = Bank_Active;
                  else if (write_select)
                    next_state = Writing;
                  else if (read_select)
                    next_state = Reading;
                  else
                    next_state = Precharging;
            end
            
            Writing: begin
                next_state = Strobe_Wait;
            end
             
            Reading: begin
                next_state = Strobe_Wait;
            end
             
             Strobe_Wait: begin
                if (RL_WL_count >= RL_WL_MAXVALUE -1)
                    next_state = Strobe;
                else
                    next_state = Strobe_Wait;
            end
           
            Strobe: begin
                if (Strobe_count == 32'd4 + tWR - 1) // strobe 4 times and wait tWR after
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
                RESET_Output = 1'b0; //Keep RESET_Output low for 100 ns
            end
            
            Initialization: begin
                RESET_Output = 1'b1;

            end
            
            ZQ_Calibration: begin
            end
            
            Idle: begin
                CS = 1'b0;
                RAS =1'b1;
                CAS = 1'b1;
                WE = 1'b1;
                BA_out = 3'bx;
                write_DQS_to_DRAM = 1'bx;
 	
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
                Addr_out [11] = A_11;
                Addr_out [12] = A_12;
                Addr_out [14:13] = A13_14;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Write lower 8 bits
                UDM <= 1'b0;                        // Write lower 8 bits
//                Data_read <= 8'b00000000;
                //DQ <= MCRegis;                    // 16 bit data line
//                UDQS <= CLK;
//                LDQS <= CLK;
                RL_WL_MAXVALUE <= WL;
                RL_WL_count = RL_WL_count + 1; 
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
                Addr_out [11] = A_11;
                Addr_out [12] = A_12;
                Addr_out [14:13] = A13_14;
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
                LDM <= 1'b0;                        // Read lower 8 bits
                UDM <= 1'b0;                        // Read lower 8 bits
//                Data_read <= DQ;                    // This needs to be changed
//                UDQS <= CLK;
//                LDQS <= CLK;
                RL_WL_MAXVALUE <= RL;
                RL_WL_count = RL_WL_count + 1;
            end
            
//           ReadingAP: begin
//                CS <= 1'b0;
//                RAS <= 1'b1;
//                CAS <= 1'b0;
//                WE <= 1'b1;
//                Addr_out [9:0] = Addr_Column;
//                Addr_out [10] = A_10;               // 1 =  precharge
//                Addr_out [11] = A_11;     // Part of row addres
//                Addr_out [12] = A_12;               // 1 = BL8 / 0 = BC4
//                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0
//                LDM <= 1'b0;                        // Read lower 8 bits
//                UDM <= 1'b0;                        // Read lower 8 bits
//                //Data_read <= DQ;                    
                
//            end
            
            Strobe_Wait: begin
               
//                RAS = 1'b1;
//                CAS = 1'b1;     // all the address stuff for NOP command are V in the document
//                WE = 1'b1;
               
                if (RL_WL_count == RL_WL_MAXVALUE -1 && write_select) begin   // this is for one period of the clock the DQS is held low has to do with tRPRE
                                                                                // -1 because we start counting at 0
                                                                                // -1 because RL_WL_count started counting on rising edge after write command
                    write_DQS_to_DRAM = CLK;
                end
            end
           
            Strobe: begin
                  if (write_select) begin
                      if (Strobe_count <= 4)
                        write_DQS_to_DRAM = CLK;
                      else
                        write_DQS_to_DRAM = 1'b0;
                  end
                  else if (read_select) begin
                      if (Strobe_count <= 3)
                        read_DQS_from_DRAM = 1'b1;
                      else
                        read_DQS_from_DRAM = 1'b0;
                  end
            end
            
            Precharging: begin
                CS <= 1'b0;
                RAS <= 1'b0;
                CAS <= 1'b1;
                WE <= 1'b0;
                Addr_out [10] = A_10;               // 1 =  one bank / 0 = all banks
                Addr_out [11] = A_11;     // Does not matter
                Addr_out [12] = A_12;               // Does not matter
                BA_out <= BA_in;                    // 3 bit hex value, start at 3'h0 / Does not matter IF A_10 == 0
                LDM <= 1'b1;                        // Ignore lower 8 bits
                UDM <= 1'b1; 
                
                //For showcasing
//                Addr_out [9:0] = 10'bx;
//                Data_read = 16'bx;
                
                precharge_timer = 0;
            end

                
        endcase
            
    end
    
    // Tri-state buffer to control my_bus
    assign DQ[7:0] = (DQ_dir) ? Data_Write : 8'bz;
    
    
   // READING based off the strobe
   // if read_DQS_from_DRAM is high, start collecting data from DQ line
    always @(clk_90) begin
        if (read_DQS_from_DRAM) begin
             DQ_read_bitline = DQ_read_bitline + 1;
             case(DQ_read_bitline)
                1: begin
                    Data_read[0] <= DQ[0];
                end
                2: begin
                    Data_read[1] <= DQ[1];
                end
                3: begin
                    Data_read[2] <= DQ[2];
                end
                4: begin
                    Data_read[3] <= DQ[3];
                end
                5: begin
                    Data_read[4] <= DQ[4];
                end
                6: begin
                    Data_read[5] <= DQ[5];
                end
                7: begin
                    Data_read[6] <= DQ[6];
                end
                8: begin
                    Data_read[7] <= DQ[7];
                end
                default: begin
                    DQ_read_bitline = 0;
                end          
             endcase
        end
        else
            DQ_read_bitline = 0;
                
    end
     
    phase_shifted_clock phaseShift (
        .clk_in(CLK),
        .rst(1'b0),
        .clk_out(clk_90)    
    );
    
endmodule




















//--- I don't think we're using this phase shifted clock clk_out or clk_shifted but we're actually using clk_90? ---





module phase_shifted_clock (
    input  wire clk_in,   // Input clock (e.g., 100 MHz)
    input  wire rst,      // Reset
    output wire clk_out  // Phase-shifted clock output
);

    wire clk_fb;       // Feedback clock for MMCM
    wire clk_shifted;  // 90-degree phase-shifted clock
    wire locked;       // MMCM lock signal

    // Create MMCM phase-shifted clock by 90 degrees. This allows reading DQS between rising and falling edges of clk_in
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


    assign clk_out = clk_shifted; // Output the shifted clock

endmodule



