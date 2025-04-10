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

// Inputs and outputs in OuterSource are used in the Constraints file
module OuterSource(
    // Inputs - From development board / FPGA to memory controller code
    
    input wire sysclk_p,                // Differential positive signal from development board - 200MHz (5ns)
    input wire sysclk_n,                // Differential negative signal from development board - 200MHz (5ns)
    input wire RESET_SM_button,         // Reset state machine command, issued by pressing top button
    input wire btnl,                    // Write command, issued by pressing left button
    input wire btnr,                    // Read command, issued by pressing left button
    input wire [7:0] switch,            // To write data to DRAM, high = 1 | low = 0
    
    // Inouts - Between memory controller and DRAM
    
    inout wire [15:0] DQ,               // Data line connecting between memory controller and DRAM
    inout wire LDQS,                    // Write & Read - Lower 8 bit data strobe, oscillates at each bit we read or write
    inout wire LDQS_n,                  // Differential pair to LDQS
    inout wire UDQS,                    // Write & Read - Upper 8 bit data strobe, oscillates at each bit we read or write
    inout wire UDQS_n,                  // Differential pair to UDQ
    
    // Outputs - From memory controller to DRAM
    
    output wire CS,                     // Active Low - Chip select - Used to select state - Almost always active
    output wire RAS,                    // Active Low - Row Address Strobe - Used to select state - Active in Refresh / Precharge / Activate
    output wire CAS,                    // Active Low - Column Address Strobe  - Used to select state - Active in Refresh / Write / Read
    output wire WE,                     // Active Low - Write Enable - Used to select state - Active in Precharge / Write
    output wire RESET_DRAM,             // Reset (Reset command to DRAM Reset pin)
    output wire [14:0] Addr_out,        // Row or Column address depending on state
    output wire [2:0] BA_out,           // Bank address
    output wire LDM,                    // Write - Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output wire UDM,                    // Write - Uppder 8 bit data mask - Write = 0 / Ignore (mask) data = 1
    output wire [7:0] led,              // To read data from DRAM, on = 1 | off = 0
    
    output wire CK,                     // Differential clock positive edge, supplies clk for DRAM (320 MHz, 3.1ns)
    output wire CK_n,                   // Differential clock negative edge, supplies clk for DRAM (320 MHz, 3.1ns)
    output wire CKE                     // Clock Enable - Should be set high for most states
    
    );    

    assign CKE = 1'b1;
    
    wire Refresh;                       // Refresh logic is at bottom of file
    
    // Currently makes right-most LED turn on while in IDLE state. Used for testing
    wire [5:0] state_out;
//    assign led[0] = (state_out == 5'd4) ? 1'b1 : 1'b0;
  
    // Create clk for state machine to use from differential sysclk inputs   
    wire clk; // (320 MHz, 3.1ns)
    wire clk_double_speed;

    clock_generator create_31ns_clk(
    .clk_200_p(sysclk_p),   // Differential clock input (positive)
    .clk_200_n(sysclk_n),   // Differential clock input (negative)
    .rst(0),         // Reset input
    .clk_640(clk_double_speed),     // Generated 640 MHz clock
    .locked()       // MMCM locked status
    );

    clock_divider_by_2 divider(
    .clk_in(clk_double_speed),
    .rst(1'b0),
    .clk_out(clk)
    ); 

//    IBUFDS clk_in_inst (
//    .O(clk),       // Single-ended output clock
//    .I(sysclk_p),        // Differential input positive
//    .IB(sysclk_n)      // Differential input negative
//);

    
    // Create Differential CK and CK_n from clk. These are outputted directly to the DRAM, not used in the Big_SM_Template SM
     OBUFDS clkout_inst (
        .O(CK),                         // Differential output positive
        .OB(CK_n),                      // Differential output negative
        .I(clk)                         // Single-ended input clock
    );
    
    // Inputs and outputs to our memory controller, which will pass through our OuterSource variables to reach the contraints file
    Big_SM_Template SM (
         // Inputs
        .CLK(clk),                      // 200 Mhz / 200 ns
//        .Reset_input(RESET_SM_button),     // We should have a reset button to trigger the reset?
        .ZQCL(1'b1),                    // ZQ Calibration - Set high
        .MRS(1'b0),                     // Mode Registers - Set low
        .REF(Refresh),                  // Refresh - Every 64 ms
//        .CKE(CKE),                    // For clarity I think we should assign this to 1 inside our state machine instead of in outer_source
        .ACT(1'b0),                     //  Activate state - No longer used, as we have write or read commands automatically activate
        .WRITE(btnl),                   // Write command - Controlled by left button
        .READ(btnr),                    // Read command - Controlled by right button
//        .PRE(PRE)                     Not currently using, could probably get rid of?
        .Addr_Row(15'd5),               // Used during Activate state, open until next precharge
        .Addr_Column(10'd1),            // Used during Write and Read states
        .A_10(1'b0),                    // Write & Read - Precharge Y = 1 / N = 0  |  Precharge - One bank = 0 / All banks = 1
        .A_11(1'b1),                    // Write & Read - Additional column address
        .A_12(1'b1),                    // Write & Read - 1 = BL8 (Burst Length 8 bits) / 0 = BC4 (Burst Chop 4 bits)
        .A13_14(2'b00),                 // Write & Read - Unnecessary bits
        .BA_in(3'b101),                 // Activate | Write | Precharge (sometimes) - Bank Address
        .Data_Write(switch),            // Write - 1 byte is written from our development board switches to the DQ line
        
        // Inout
        .DQ(DQ[7:0]),                   // Data line connecting between memory controller and DRAM
        .LDQS(LDQS),                    // Write & Read - Lower 8 bit data strobe, oscillates at each bit we read or write
        .LDQS_n(LDQS_n),                // Differential pair to LDQS
        .UDQS(UDQS),                    // Write & Read - Upper 8 bit data strobe, oscillates at each bit we read or write
        .UDQS_n(UDQS_n),                // Differential pair to UDQ
        
        // Outputs
        .Data_read(led[7:0]),           // Read - 1 byte from DQ is read to this reg. It is then outputted to our LEDs
        .CS(CS),                        // Active Low - Chip select - Used to select state - Almost always active
        .RAS(RAS),                      // Active Low - Row Address Strobe - Used to select state - Active in Refresh / Precharge / Activate
        .CAS(CAS),                      // Active Low - Column Address Strobe  - Used to select state - Active in Refresh / Write / Read
        .WE(WE),                        // Active Low - Write Enable - Used to select state - Active in Precharge / Write
        .RESET_Output(RESET_DRAM),                  // Reset (Reset command to DRAM Reset pin)
        .Addr_out(Addr_out),            // Row or Column address depending on state
        .BA_out(BA_out),                // Bank address
        .LDM(LDM),                      // Write - Lower 8 bit data mask - Write = 0 / Ignore (mask) data = 1
        .UDM(UDM),                      // Write - Upper 8 bit data mask - Write = 0 / Ignore (mask) data = 1

        .state(state_out)               // Output current state, currently used during testing
        
    );
    
    // Refresh Logic
    
//    localparam integer Refresh_Value = 32'd20645161;  // Every time Refresh_clock reaches this value - Refresh all banks (Every 64 ms based on 320MHz)
//    localparam integer Reset_Counter = 32'd20645211;  // Every time Refresh_clock reaches this value - Reset the Refresh_clock to 0
    localparam integer Refresh_Value = 32'd200;  // Every time Refresh_clock reaches this value - Refresh all banks (Every 64 ms based on 320MHz)
    localparam integer Reset_Counter = 32'd205;  // Every time Refresh_clock reaches this value - Reset the Refresh_clock to 0
        
    reg [31:0] Refresh_clock = 0;                    // Counts between 0 and Refresh_Value to refresh DRAM every 64 ms
    
    // Counting logic for Refresh_clock, from 0 to Reset_Counter
    
    always @(posedge clk or posedge RESET_SM_button) begin
        if (RESET_SM_button)
            Refresh_clock <= 0;
        else begin
            if (Refresh_clock >= Reset_Counter)
                Refresh_clock <= 0;
            else
                Refresh_clock <= Refresh_clock + 1;
        end
    end
    
    // Refresh is set high (True = 1) when Refresh_clock reaches or exceeds THRESHOLD, otherwise it remains low (False = 0)
    
    assign Refresh = (Refresh_clock >= Refresh_Value);
    
    
endmodule

// Clock Divider written by ChatGPT
module clock_divider_by_2(
    input  wire clk_in,   // Input clock (640 MHz)
    input  wire rst,      // Reset input
    output wire clk_out   // Output clock (320 MHz)
);

// Internal signal to hold the divided clock
reg clk_div;

initial begin
 clk_div <= 1'b1;
end

// Process to divide the clock by 2
always @(posedge clk_in or posedge rst) begin
    if (rst) begin
        clk_div <= 1'b0;  // Reset the divided clock
    end else begin
        clk_div <= ~clk_div;  // Toggle the divided clock on each rising edge of the input clock
    end
end

// Assign the divided clock to the output
assign clk_out = clk_div;

endmodule



// MMCM Source - Chatgpt
module clock_generator(
    input  wire clk_200_p,   // Differential clock input (positive) from the source
    input  wire clk_200_n,   // Differential clock input (negative) from the source
    input  wire rst,         // Reset input to the MMCM and system
    output wire clk_640,     // Generated clock output at 640 MHz
    output wire locked       // Lock status output, indicates whether the MMCM has locked
);

// Internal signals
wire clk_200_ibuf;    // Internal wire to hold the single-ended version of the input clock
wire clk_mmcm_fb;     // Feedback clock used by MMCM to maintain phase lock
wire clk_mmcm_out;    // The output clock from the MMCM
wire locked_int;      // Internal version of the locked signal

// Convert differential input clock to single-ended using IBUFDS (Input Buffer)
IBUFDS #(
    .DIFF_TERM("TRUE"),   // Enable internal termination for differential inputs
    .IBUF_LOW_PWR("TRUE"), // Use low-power I/O buffer
    .IOSTANDARD("DEFAULT") // Default I/O standard
) IBUFDS_inst (
    .O(clk_200_ibuf),   // Single-ended output for clock input
    .I(clk_200_p),       // Positive differential input
    .IB(clk_200_n)       // Negative differential input
);

// MMCM Instantiation to generate the 640 MHz clock
MMCME2_ADV #(
    .BANDWIDTH("OPTIMIZED"),   // Set the MMCM to optimized performance for better accuracy
    .CLKFBOUT_MULT_F(16.0),     // Multiply the input clock by 16 (M = 16), resulting in a VCO frequency of 3200 MHz
    .CLKIN1_PERIOD(5.0),        // Input clock period is 5 ns (200 MHz), 1 / 200 MHz = 5 ns
    .DIVCLK_DIVIDE(5),          // Divide the VCO output by 5 (D = 5) to get the desired output frequency
    .CLKOUT0_DIVIDE_F(1.0),     // Divide the output clock by 1 (O = 1) to keep the output frequency at 640 MHz
    .STARTUP_WAIT("FALSE")      // Disable the startup wait to speed up the locking process
) mmcm_inst (
    .CLKIN1(clk_200_ibuf),     // The single-ended input clock to the MMCM
    .CLKFBIN(clk_mmcm_fb),     // Feedback clock from the MMCM output, used to phase lock the MMCM
    .CLKFBOUT(clk_mmcm_fb),    // Feedback clock output, sent back to CLKFBIN to maintain phase alignment
    .CLKOUT0(clk_mmcm_out),    // Output clock from the MMCM (640 MHz in this case)
    .LOCKED(locked_int),       // Internal locked signal indicating if MMCM has stabilized
    .PWRDWN(1'b0),             // Power down signal, set to 0 (disabled)
    .RST(rst)                  // Reset signal to reset the MMCM
);

// Buffer the MMCM output clock to drive the final output
BUFG clkout_buf (
    .O(clk_640),        // The 640 MHz output clock
    .I(clk_mmcm_out)    // The internal MMCM output clock
);

// Assign the locked signal to the external wire to indicate if the MMCM is locked
assign locked = locked_int; // Output the internal locked signal as the final locked status

endmodule

