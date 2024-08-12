`timescale 1 ns/ 1 ns
module qspi_controller_vlg_tst();

// Constants
parameter CLK_PERIOD = 20; // 50MHz clock

// Test vector input registers
reg    system_clk;
reg    system_reset_n;
reg    [1:0] mode;
reg    [31:0] read_addr;
reg    [15:0] total_data_num;
reg    key;
reg    switch_die;

// Wires
wire    spi_clk;
wire    cs_n;
wire    [7:0] qspidata2spi_read;
wire    read_done;

// Bidirectional IOs
wire    io0, io1, io2, io3;
reg    io0_reg, io1_reg, io2_reg, io3_reg;
reg    io0_oe, io1_oe, io2_oe, io3_oe;

assign io0 = io0_oe ? io0_reg : 1'bz;
assign io1 = io1_oe ? io1_reg : 1'bz;
assign io2 = io2_oe ? io2_reg : 1'bz;
assign io3 = io3_oe ? io3_reg : 1'bz;

// Instantiate the Unit Under Test (UUT)
qspi_controller uut (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .key(key),
    .addr(read_addr),
    .total_data_num(total_data_num),
    .switch_die(switch_die),
    .mode(mode),
    .spi_clk(spi_clk),
    .cs_n(cs_n),
    .io0(io0),
    .io1(io1),
    .io2(io2),
    .io3(io3),
    .qspidata2spi_read(qspidata2spi_read),
    .read_done(read_done)
);


// Clock generation
always begin
    #(CLK_PERIOD/2) system_clk = ~system_clk;
end

// Test procedure
initial begin
    // Initialize inputs
    system_clk = 0;
    system_reset_n = 0;
    key = 0;
    read_addr = 32'h00000000;
    total_data_num = 16'd12;  
    switch_die = 0;
    mode = 2'b00;
    io0_oe = 0;
    io1_oe = 0;
    io2_oe = 0;
    io3_oe = 0;
    io0_reg = 0;
    io1_reg = 0;
    io2_reg = 0;
    io3_reg = 0;
    // Reset
    #100 system_reset_n = 1;
    #100;
    $display("Running testbench");
    // Test Case 1: Standard Read Mode
    $display("Test Case 1: Standard Read Mode");
    mode = 2'b00;
    read_addr = 32'h000000BB;
    switch_die = 0;
    key = 1;
    #20 key = 0;
    #3210;
    io0_oe = 0;
    io1_oe = 1;
    repeat(12)
        begin
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
        end

    wait (read_done == 1)
    io0_oe = 0;
    io1_oe = 0;
    system_reset_n = 0;
    #100 system_reset_n = 1;
    #100;
    // Test Case 2: Dual Read Mode
    $display("Test Case 2: Dual Read Mode");
    mode = 2'b01;
    read_addr = 32'h000000CC;
    switch_die = 0;
    key = 1;
    #20 key = 0;
    #3820;
    io0_oe = 1;
    io1_oe = 1;
    repeat(12)
        begin
            @(negedge spi_clk) 
                begin
                    io1_reg = 1'b1;
                    io0_reg = 1'b1;
                end
            @(negedge spi_clk) 
                begin
                    io1_reg = 1'b1;
                    io0_reg = 1'b0;
                end
            @(negedge spi_clk) 
                begin
                    io1_reg = 1'b1;
                    io0_reg = 1'b1;
                end
            @(negedge spi_clk) 
                begin
                    io1_reg = 1'b1;
                    io0_reg = 1'b0;
                end
        end

    wait (read_done == 1)
    io0_oe = 0;
    io1_oe = 0;
    system_reset_n = 0;
    
    #100 system_reset_n = 1;
    #100
    // Test Case 3: Quad Read Mode
    $display("Test Case 3: Quad Read Mode");
    mode = 2'b10;
    read_addr = 32'h000000DD;
    switch_die = 0;
    key = 1;
    #20 key = 0;
    #3820;
    io0_oe = 1;
    io1_oe = 1;
    io2_oe = 1;
    io3_oe = 1;
    repeat(12)
        begin
            @(negedge spi_clk) 
                begin
                    io3_reg = 1'b1;
                    io2_reg = 1'b0;
                    io1_reg = 1'b1;
                    io0_reg = 1'b1;
                end
            @(negedge spi_clk) 
                begin
                    io3_reg = 1'b1;
                    io2_reg = 1'b1;
                    io1_reg = 1'b0;
                    io0_reg = 1'b1;
                end
        end

    wait (read_done == 1)
    io0_oe = 0;
    io1_oe = 0;
    io2_oe = 0;
    io3_oe = 0;
    system_reset_n = 0;

    #100 system_reset_n = 1;
    #100
    $display("Test Case 4: Switch die Mode");
    mode = 2'b00;
    read_addr = 32'h01FFFFFA;
    total_data_num = 16'd6;
    switch_die = 0;
    key = 1;
    #20 key = 0;
    #3210;
    io0_oe = 0;
    io1_oe = 1;    
    repeat(6)
        begin
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
        end
    wait (read_done == 1)
    io0_oe = 0;
    io1_oe = 0;
    system_reset_n = 0;

    #20 system_reset_n = 1;
    switch_die = 1;
    key = 1;
    #20 key = 0;
    #1310
    system_reset_n = 0;

    #100 system_reset_n = 1;
    #100
    read_addr = 32'h00000000;
    total_data_num = 16'd3;
    mode = 2'b00;
    switch_die = 0;
    key = 1;
    #20 key = 0;

    #3210;
    io0_oe = 0;
    io1_oe = 1;
    repeat(3)
        begin
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
            @(negedge spi_clk) io1_reg = 1'b1;
            @(negedge spi_clk) io1_reg = 1'b0;
        end

    wait (read_done == 1)
    io0_oe = 0;
    io1_oe = 0;
    system_reset_n = 0;

    $display("All test cases completed");
    #1000 $stop;
end
endmodule