`timescale 1 ns/ 1 ns
module spi_flash_read_vlg_tst();

// test vector input registers
reg    [31:0] start_addr;
reg    [31:0] end_addr;
reg    [1:0] mode;
reg    read_req;
reg    start_flag;
reg    system_clk;
reg    system_reset_n;
reg    switch_die_need;


// wires                                               
wire    read_finish;
wire    sfr2qspi_io0, sfr2qspi_io1, sfr2qspi_io2, sfr2qspi_io3;
wire    cs_n;
wire    spi_clk;
wire    [15:0] rom_data_num;
wire    [7:0] fifo_output;

reg    io0_dir, io1_dir, io2_dir, io3_dir;
reg    io0_out, io1_out, io2_out, io3_out;

assign sfr2qspi_io0 = io0_dir ? io0_out : 1'bz;
assign sfr2qspi_io1 = io1_dir ? io1_out : 1'bz;
assign sfr2qspi_io2 = io2_dir ? io2_out : 1'bz;
assign sfr2qspi_io3 = io3_dir ? io3_out : 1'bz;


// instantiate the Unit Under Test (UUT)
spi_flash_read uut (
    .start_addr(start_addr),
    .end_addr(end_addr),
    .mode(mode),
    .spi_read_req(read_req),
    .start_flag(start_flag),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .switch_die_need(switch_die_need),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3),
    .read_finish(read_finish),
    .cs_n(cs_n),
    .spi_clk(spi_clk),
    .rom_data_num(rom_data_num),
    .fifo_output(fifo_output)
);

// Clock generation
always #10 system_clk = ~system_clk;

initial
begin
    $display("Running testbench");
    system_reset_n = 0;
    system_clk = 0;
    start_flag = 0;
    start_addr = 32'h00000000;
    end_addr = 32'h00000000;
    mode = 2'b00;
    read_req = 0;
    switch_die_need = 0;
    io0_dir = 0;
    io1_dir = 0;
    io2_dir = 0;
    io3_dir = 0;
    io0_out = 0;
    io1_out = 0;
    io2_out = 0;
    io3_out = 0;

    #100 system_reset_n = 1;
    #100;
    // Test 1: Basic read operation
    $display("Test 1: Basic read operation");
    start_addr = 32'h00000000;
    end_addr = 32'h0000000B;
    mode = 2'b00;
    switch_die_need = 0;    
    start_flag = 1;
    #20 start_flag = 0;
    #3210;
    io1_dir = 1;
    io0_dir = 0;

    repeat(12)
        begin 
            @(negedge spi_clk) io1_out = 1'b1;
            @(negedge spi_clk) io1_out = 1'b0;
            @(negedge spi_clk) io1_out = 1'b1;
            @(negedge spi_clk) io1_out = 1'b0;
            @(negedge spi_clk) io1_out = 1'b1;
            @(negedge spi_clk) io1_out = 1'b0;
            @(negedge spi_clk) io1_out = 1'b1;
            @(negedge spi_clk) io1_out = 1'b0;
            read_req = 1;
            #20 read_req = 0;
        end
    wait (uut.qspi_ctrl4read.read_done);
    io0_dir = 0;
    io1_dir = 0;

    wait(read_finish);
    #100;
    system_reset_n = 0;
    #100 system_reset_n = 1;
    #100;    
    // Test 2: Dual read operation
    $display("Test 2: Dual read operation");
    start_addr = 32'h00001000;
    end_addr = 32'h0000100B;
    mode = 2'b01;
    switch_die_need = 0;
    start_flag = 1;
    #20 start_flag = 0;
    #3820;
    io1_dir = 1;
    io0_dir = 1;
    repeat(12)
        begin
            @(negedge spi_clk)
                begin
                    io1_out = 1'b1;
                    io0_out = 1'b1;
                end
            @(negedge spi_clk)
                begin
                    io1_out = 1'b1;
                    io0_out = 1'b0;
                end
            @(negedge spi_clk)
                begin
                    io1_out = 1'b1;
                    io0_out = 1'b1;
                end
            @(negedge spi_clk)
                begin
                    io1_out = 1'b1;
                    io0_out = 1'b0;
                end
            read_req = 1;
            #20 read_req = 0;
        end
    wait (uut.qspi_ctrl4read.read_done);
    io0_dir = 0;
    io1_dir = 0;
    wait(read_finish);
    system_reset_n = 0;

    #100 system_reset_n = 1;
    #100;

    // Test 3: Quad read operation
    $display("Test 3: Quad read operation");
    start_addr = 32'h00002000;
    end_addr = 32'h0000200B;
    switch_die_need = 0;
    mode = 2'b10;
    start_flag = 1;
    #20 start_flag = 0;
    #3820;
    io0_dir = 1;
    io1_dir = 1;
    io2_dir = 1;
    io3_dir = 1;
    repeat(12)
        begin
            @(negedge spi_clk) 
                begin
                    io3_out = 1'b1;
                    io2_out = 1'b0;
                    io1_out = 1'b1;
                    io0_out = 1'b1;
                end
            @(negedge spi_clk) 
                begin
                    io3_out = 1'b1;
                    io2_out = 1'b1;
                    io1_out = 1'b0;
                    io0_out = 1'b1;
                end
            read_req = 1;
            #20 read_req = 0;
        end
    wait (uut.qspi_ctrl4read.read_done);    
    io0_dir = 0;
    io1_dir = 0;
    io2_dir = 0;
    io3_dir = 0;
    wait(read_finish);
    system_reset_n = 0;
    #100;

    // // Test 4: Switch die operation
    // $display("Test 4: Switch die operation");
    // start_addr = 32'h01FFFFFA;
    // end_addr = 32'h02000010;
    // mode = 2'b00;
    // switch_die_need = 1;
    // start_flag = 1;
    // #20 start_flag = 0;
    // for (i = 0; i < 24; i = i + 1)
    //     begin
    //         #3210;
    //         io1_dir = 1;
    //         io0_dir = 0;
    //         repeat(8) 
    //             begin
    //                 @(negedge spi_clk) io1_out = $random;
    //             end
    //         io0_dir = 0;
    //         io1_dir = 0;
    //     end
    // wait(read_finish);
    // start_flag = 0;
    #1000 $stop;
end


endmodule