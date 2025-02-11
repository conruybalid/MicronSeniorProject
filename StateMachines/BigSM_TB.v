`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2025 12:21:19 PM
// Design Name: 
// Module Name: BigSM_TB
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


module BigSM_TB();
// Inputs
  reg CLK;
  reg RESET;
  reg ZQCL;
  reg MRS;
  reg SRE;
  reg SRX;
  reg REF;
  reg PDE;
  reg PDX;
  reg CKE;
  reg ACT;
  reg WRITE;
  reg READ;
  reg WRITE_AP;
  reg READ_AP;
  reg PRE;

  // Outputs
  wire CS;
  wire RAS;
  wire CAS;
  wire WE;

  // Instantiate the Unit Under Test (UUT)
  Big_SM_Template uut (
    .CLK(CLK), 
    .RESET(RESET), 
    .ZQCL(ZQCL), 
    .MRS(MRS), 
    .SRE(SRE), 
    .SRX(SRX), 
    .REF(REF), 
    .PDE(PDE), 
    .PDX(PDX), 
    .CKE(CKE), 
    .ACT(ACT), 
    .WRITE(WRITE), 
    .READ(READ), 
    .WRITE_AP(WRITE_AP), 
    .READ_AP(READ_AP), 
    .PRE(PRE), 
    .CS(CS), 
    .RAS(RAS), 
    .CAS(CAS), 
    .WE(WE)
  );

  initial begin
    // Initialize Inputs
    CLK = 0;
    RESET = 0;
    ZQCL = 0;
    MRS = 0;
    SRE = 0;
    SRX = 0;
    REF = 0;
    PDE = 0;
    PDX = 0;
    CKE = 0;
    ACT = 0;
    WRITE = 0;
    READ = 0;
    WRITE_AP = 0;
    READ_AP = 0;
    PRE = 0;

    // Apply reset
    RESET = 1;
    #10;
    RESET = 0;

    // Add stimulus here
    // Example stimulus
    #20 
    ZQCL = 1; // State: Initialization (2) -> ZQ_Calibration (3)
    #20 
    ZQCL = 0; // State: ZQ_Calibration (3) -> Idle (4)
    #20 
    MRS = 1;  // State: Idle (4) -> Write_Leveling (5)
    #20 
    MRS = 0;  // State: Write_Leveling (5) -> Idle (4)
    #20 
    REF = 1;
    #20 
    REF = 0;
    #150
    ACT = 1;
    #20 
    ACT = 0;
    WRITE = 1;
    #20
    WRITE = 0;
    PRE = 1;
    
    
    // Finish simulation
    #100;
    $finish;
  end

  // Clock generation
  always #5 CLK = ~CLK;
endmodule
