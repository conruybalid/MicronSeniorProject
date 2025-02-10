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
    input SRE,
    input SRX,
    input REF,
    input PDE,
    input PDX,
    input CKE,
    input ACT,
    input WRITE,
    input READ,
    input WRITE_AP,
    input READ_AP,
    input PRE,
    output CS,
    output RAS,
    output CAS,
    output WE
//    output [2:0] BA,
//    output [15:0] A,
//    output BC,
//    output AP
    );
    
    reg [4:0] state;
    reg [4:0] next_state;
     
parameter Power_On = 0,
          Reset_Procedure = 1,
          Initialization = 2,
          ZQ_Calibration = 3,
          Idle = 4,
          Write_Leveling = 5,
          Self_Refresh = 6,
          Refreshing = 7,
          Precharge_Power_Down = 8,
          Activating = 9,
          Bank_Active = 10,
          Active_Power_Down = 11,
          Writing = 12,
          WritingAP = 13,
          Reading = 14,
          ReadingAP = 15,
          Precharging = 16;

reg [8*20:1] state_name; // 20-character string

always @(*) begin
    case (state)
        Power_On: state_name = "Power_On";
        Reset_Procedure: state_name = "Reset_Procedure";
        Initialization: state_name = "Initialization";
        ZQ_Calibration: state_name = "ZQ_Calibration";
        Idle: state_name = "Idle";
        Write_Leveling: state_name = "Write_Leveling";
        Self_Refresh: state_name = "Self_Refresh";
        Refreshing: state_name = "Refreshing";
        Precharge_Power_Down: state_name = "Precharge_Power_Down";
        Activating: state_name = "Activating";
        Bank_Active: state_name = "Bank_Active";
        Active_Power_Down: state_name = "Active_Power_Down";
        Writing: state_name = "Writing";
        WritingAP: state_name = "WritingAP";
        Reading: state_name = "Reading";
        ReadingAP: state_name = "ReadingAP";
        Precharging: state_name = "Precharging";
        default: state_name = "Unknown";
    endcase
end
     
    // Initialize state
    initial begin
        state = Power_On;
        next_state = Reset_Procedure;
    end
     
     
    // State Transition logic
    always @(posedge CLK) begin
        
        //Transition changes
        
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
                if (MRS && !(SRE || REF || PDE || ACT))
                    next_state = Write_Leveling;
                else if (SRE && !(MRS || REF || PDE || ACT))
                    next_state = Self_Refresh;
                else if (REF && !(MRS || SRE || PDE || ACT))
                    next_state = Refreshing;
                else if (PDE && !(MRS || SRE || REF || ACT))
                    next_state = Precharge_Power_Down;
                else if (ACT && !(MRS || SRE || REF || PDE))
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
                next_state = Idle;
            end
            
            Precharge_Power_Down: begin
                // Hmm, this one needs to work without the clock running
            end
            
            Activating: begin
                next_state = Bank_Active;
            end
            
            Bank_Active: begin
                if (PDX && !(WRITE || WRITE_AP || READ || READ_AP || PRE))
                    next_state = Active_Power_Down;
                else if (WRITE && !(PDX || WRITE_AP || READ || READ_AP || PRE))
                    next_state = Writing;
                else if (WRITE_AP && !(PDX || WRITE || READ || READ_AP || PRE))
                    next_state = WritingAP;
                else if (READ && !(PDX || WRITE || WRITE_AP || READ_AP || PRE))
                    next_state = Reading;
                else if (READ_AP && !(PDX || WRITE || WRITE_AP || READ || PRE))
                    next_state = ReadingAP;
                else if (PRE && !(PDX || WRITE || WRITE_AP || READ || READ_AP))
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
//                CS = 1'b0;
//                RAS =1'b1;
//                CAS = 1'b1;
//                WE = 1'b1;		      
            end
            
            Write_Leveling: begin
            end
            
            Self_Refresh: begin
            end
            
            Refreshing: begin
            end
            
            Precharge_Power_Down: begin
            end
            
            Activating: begin
            end
            
            Bank_Active: begin
            end
            
            Active_Power_Down: begin
            end
            
            Writing: begin
            end
            
            WritingAP: begin
            end
            
            Reading: begin
            end
            
            ReadingAP: begin
            end
            
            Precharging: begin
            end

                
        endcase
            
    end
    

    
    
endmodule
