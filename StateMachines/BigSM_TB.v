`timescale 1ns / 1ps

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
  
  reg [14:0] Addr_Row;
  reg [9:0] Addr_Column;
  reg Addr_Column_11;
  reg A_10;
  reg A_12;
  reg [2:0] BA_in;
  reg [15:0] DQ_in;

  // Outputs
  wire CS;
  wire RAS;
  wire CAS;
  wire WE;
  wire [14:0] Addr_out;
  wire [2:0] BA_out;
  wire LDM, UDM;
  wire [15:0] DQ_out;
  wire UDQS, LDQS;
  
  wire [15:0] DQ_line;
  

  // Instantiate the Unit Under Test (UUT)
  Big_SM_Template uut (
    .CLK(CLK), 
    .RESET(RESET), 
    .ZQCL(ZQCL), 
    .MRS(MRS), 
    // States
    
    .REF(REF), 
    .CKE(CKE), 
    .ACT(ACT), 
    .WRITE(WRITE), 
    .READ(READ), 
    .WRITE_AP(WRITE_AP), 
    .READ_AP(READ_AP), 
    .PRE(PRE), 
    // Commands
    .CS(CS), 
    .RAS(RAS), 
    .CAS(CAS), 
    .WE(WE),
    // Bank Address
    .BA_in(BA_in),
    .BA_out(BA_out),
    // Row Addresses
    .Addr_Row(Addr_Row),
    // Column Addresses
    .Addr_Column(Addr_Column), // [9:0]
    .Addr_Column_11(Addr_Column_11),
    .Addr_out(Addr_out),
    .A_10(A_10),
    .A_12(A_12),
    .DQ_read(DQ_out),
    .Data_input(16'b1111000000000000),
    .DQ(DQ_line),
    
    // Extra outputs
    .LDM(LDM),
    .UDM(UDM),
    .UDQS(UDQS),
    .LDQS(LDQS)
  );

  // Clock generation
  always #5 CLK = ~CLK;
  
  initial begin
    // Initialize Inputs
    CLK    = 0;
    RESET  = 0;
    ZQCL   = 0;
    MRS    = 0;
    SRE    = 0;
    SRX    = 0;
    REF    = 0;
    PDE    = 0;
    PDX    = 0;
    CKE    = 0;
    ACT    = 0;
    WRITE  = 0;
    READ   = 0;
    WRITE_AP = 0;
    READ_AP  = 0;
    PRE    = 0;

    // Apply reset
    RESET = 1;
    #10;
    RESET = 0;
    
    // Apply test case 1
    #10 Addr_Row       = 15'd5;
        Addr_Column    = 10'd7;
        Addr_Column_11 = 1'b0;
        A_10          = 1'b0;
        A_12          = 1'b0;
        BA_in         = 3'b011;  // Fixed width mismatch
        DQ_in         = 16'hF00F;

    // Apply test case 2
    #20 Addr_Row       = 15'h5D6E;
        Addr_Column    = 10'h7F8;
        Addr_Column_11 = 1'b0;
        A_10          = 1'b0;
        A_12          = 1'b0;
        BA_in         = 3'b010;
        DQ_in         = 16'hA5A5;
    
    // Stimulus sequence
    #20 ZQCL = 1; // State: Initialization (2) -> ZQ_Calibration (3)
    #20 ZQCL = 0; // State: ZQ_Calibration (3) -> Idle (4)
    #20 MRS = 1;  // State: Idle (4) -> Write_Leveling (5)
    #20 MRS = 0;  // State: Write_Leveling (5) -> Idle (4)
    #20 REF = 1;
    #20 REF = 0;
    #150 WRITE = 1; 
    #50 REF = 1;
    #20 REF = 0;
    WRITE = 0;
        
    #150 READ = 1;
    #150 READ = 0;
    
    // Finish simulation
    #100;
    $finish;
  end
  
  assign DQ_line = (CS == 1'b0 && RAS == 1'b1 && CAS == 1'b0 && WE == 1'b1) ? 16'h0F00 : 16'bz;

endmodule
