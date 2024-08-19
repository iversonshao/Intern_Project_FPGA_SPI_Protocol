`timescale 1 ns/ 1 ns
module flash_se_ctrl_vlg_tst();

// Constants
parameter CLK_PERIOD = 20; // 50MHz clock
// Wire define
wire    cs_n;
wire    spi_clk;
wire    io0;
wire    se_done;

// Reg define
reg    system_clk;
reg    system_reset_n;
reg    key;
reg    [31:0] addr;


// Instantiate the flash_se_ctrl module
flash_se_ctrl flash_se_ctrl_inst (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .key(key),
    .addr(addr),
    .cs_n(cs_n),
    .spi_clk(spi_clk),
    .io0(io0),
    .se_done(se_done)
);

always
    begin
        #(CLK_PERIOD/2) system_clk = ~system_clk;
    end

// Clock, reset, and key simulation
// Simulate Flash memory behavior
reg    [7:0] flash_memory [0:4095]; // 4KB sector
integer i;
initial 
    begin
        // Initialize Flash memory (you can modify this as needed)
        for (i = 0; i < 4096; i = i + 1) 
            begin
                if    (i >= 1024 && i < 2048) // Assume 1KB-2KB has data
                    begin
                        flash_memory[i] = 8'hAA;
                    end
                else if    (i >= 2048 && i < 3072) // Assume 2KB-3KB has data
                    begin
                        flash_memory[i] = 8'hCC;
                    end
                else
                    begin
                        flash_memory[i] = 8'hFF;
                    end
            end
    end
initial 
    begin
        system_clk = 0;
        system_reset_n = 0;
        key = 0;
        addr = 32'h00000000; // Assuming this is the sector address we want to erase

        #100 system_reset_n = 1;
        #100;

        $display("Time %0t: MOSI = %b", $time, io0);
        addr = 32'h00001000;
        key = 1;
        #20 key = 0;
    end

// Check results
initial
    begin
        wait(cs_n == 1);
        #10000;

        // Check if the sector is erased
        for (i = 0; i < 4096; i = i + 1)
            begin
                if (flash_memory[i] !== 8'hFF)
                    begin
                        $display("Error: Memory not erased at address %0h", i);
                    end
            end

        $display("Sector erase operation completed");
        $finish;
    end

endmodule