`timescale 1ns / 1ps

module tb_OuterSource;

    // Declare wires and regs for the testbench signals
    reg sysclk_p;                  // Differential clock positive input
    reg sysclk_n;                  // Differential clock negative input
    reg RESET_SM_button;           // Reset state machine command
    reg btnl;                       // Write command
    reg btnr;                       // Read command
    reg [7:0] switch;              // Data to be written to DRAM
    
    // Inouts for DRAM
    wire [15:0] DQ;                // Data line between memory controller and DRAM
    wire LDQS;                     // Write & Read - Lower 8-bit data strobe
    wire LDQS_n;                   // Differential pair to LDQS
    wire UDQS;                     // Write & Read - Upper 8-bit data strobe
    wire UDQS_n;                   // Differential pair to UDQS

    // Outputs from OuterSource
    wire CS;                       // Chip select
    wire RAS;                      // Row Address Strobe
    wire CAS;                      // Column Address Strobe
    wire WE;                       // Write Enable
    wire RESET_DRAM;               // Reset to DRAM
    wire [14:0] Addr_out;          // Row or Column address
    wire [2:0] BA_out;             // Bank address
    wire LDM;                      // Write - Lower 8-bit data mask
    wire UDM;                      // Write - Upper 8-bit data mask
    wire [7:0] led;                // Read data from DRAM (LED output)
    wire CK;                       // Differential clock positive edge
    wire CK_n;                     // Differential clock negative edge
    wire CKE;                      // Clock Enable

    // Instantiate the OuterSource module
    OuterSource uut (
        .sysclk_p(sysclk_p),
        .sysclk_n(sysclk_n),
        .RESET_SM_button(RESET_SM_button),
        .btnl(btnl),
        .btnr(btnr),
        .switch(switch),
        .DQ(DQ),
        .LDQS(LDQS),
        .LDQS_n(LDQS_n),
        .UDQS(UDQS),
        .UDQS_n(UDQS_n),
        .CS(CS),
        .RAS(RAS),
        .CAS(CAS),
        .WE(WE),
        .RESET_DRAM(RESET_DRAM),
        .Addr_out(Addr_out),
        .BA_out(BA_out),
        .LDM(LDM),
        .UDM(UDM),
        .led(led),
        .CK(CK),
        .CK_n(CK_n),
        .CKE(CKE)
    );

    // Clock generation for sysclk_p and sysclk_n
    initial begin
        sysclk_p = 1;
        sysclk_n = 0;
        forever begin
            #5 sysclk_p = ~sysclk_p;  // Toggle every 5ns (200MHz)
            sysclk_n = ~sysclk_n;  // Toggle every 5ns (200MHz)
        end
    end

    // Apply reset and stimulus to buttons and switches
    initial begin
        // Initialize all signals
        RESET_SM_button = 0;
        btnl = 0;
        btnr = 0;
        switch = 8'b00000000;

        
        // Apply some test cases
        #50 switch = 8'b10101010;  // Write data to switch
        btnl = 1;                  // Simulate a write command
        #10 btnl = 0;
        
        #100 switch = 8'b11110000; // Change switch data
        btnr = 1;                  // Simulate a read command
        #10 btnr = 0;
        
        #200;
        $finish;               // End simulation after a period
    end


endmodule;
