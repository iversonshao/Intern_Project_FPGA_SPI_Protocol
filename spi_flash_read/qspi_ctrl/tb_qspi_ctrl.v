`timescale 1 ns/ 1 ns
module qspi_controller_vlg_tst();
// constants
// test vector input registers
reg    [1:0] mode;
reg    [31:0] read_addr;
reg    read_flag;
reg    switch_die;
reg    system_clk;
reg    system_reset_n;
// wires                                               
wire    cs_n;
wire    [7:0] data_qspi2fifo;

wire    io0, io1, io2, io3;
reg    io0_dir, io1_dir, io2_dir, io3_dir;
reg    io0_out, io1_out, io2_out, io3_out;

wire    read_done;
wire    ready;
wire    spi_clk;
wire    write_req;
reg    [7:0] expected_fifo_data;

// Bidirectional port assignments
assign io0 = io0_dir ? io0_out : 1'bz;
assign io1 = io1_dir ? io1_out : 1'bz;
assign io2 = io2_dir ? io2_out : 1'bz;
assign io3 = io3_dir ? io3_out : 1'bz;


// assign statements (if any)                          
qspi_controller uut (
// port map - connection between master ports and signals/registers   
    .cs_n(cs_n),
    .data_qspi2fifo(data_qspi2fifo),
    .io0(io0),
    .io1(io1),
    .io2(io2),
    .io3(io3),
    .mode(mode),
    .read_addr(read_addr),
    .read_done(read_done),
    .read_flag(read_flag),
    .ready(ready),
    .spi_clk(spi_clk),
    .switch_die(switch_die),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .write_req(write_req)
);

//generate clock
always #10 system_clk = ~system_clk;

initial
    begin
        // code that executes only once
        system_clk = 0;
        system_reset_n = 0;
        switch_die = 0;
        read_flag = 0;
        mode = 2'b00;
        read_addr = 32'h00000000;
        io0_dir = 0;
        io1_dir = 0;
        io2_dir = 0;
        io3_dir = 0;
        io0_out = 0;
        io1_out = 0;
        io2_out = 0;
        io3_out = 0;
        expected_fifo_data = 8'h00;

        #100;
        system_reset_n = 1;

        #50;
        $display("Running testbench");
        $display("Standard read operation");

        read_addr = 32'h000000BB;
        read_flag = 1;
        switch_die = 0;
        mode = 2'b00;
        expected_fifo_data = 8'b10101010;
        #830;
        io1_dir = 1;
        io0_dir = 1;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;

        wait (write_req == 1);
        io1_dir = 0;
        io0_dir = 0;
        if    (data_qspi2fifo == expected_fifo_data)
            begin
                $display("Data written to FIFO buffer is correct: %b", data_qspi2fifo);
            end
        else
            begin
                $display("FIFO DATA ERROR!! Expected: %b, Got: %b", expected_fifo_data, data_qspi2fifo);
            end
        wait (read_done == 1);
        $display("standard read operation done");
        
        #50;    
        $display("Dual read operation");
        read_addr = 32'h000000AA;
        read_flag = 1;
        switch_die = 0;
        mode = 2'b01;
        expected_fifo_data = 8'b10101010;
        
        #970;
        io0_dir = 1;
        io1_dir = 1;
        @(negedge system_clk) 
            begin
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        @(negedge system_clk) 
            begin
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        @(negedge system_clk) 
            begin
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        @(negedge system_clk) 
            begin
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        wait (write_req == 1);
        io0_dir = 0;
        io1_dir = 0;
        if    (data_qspi2fifo == expected_fifo_data)
            begin
                $display("Data written to FIFO buffer is correct: %b", data_qspi2fifo);
            end
        else
            begin
                $display("FIFO DATA ERROR!! Expected: %b, Got: %b", expected_fifo_data, data_qspi2fifo);
            end
        wait (read_done == 1);
        $display("dual read operation done");

        #50;
        $display("Quad read operation");
        read_addr = 32'h000000AA;
        read_flag = 1;
        switch_die = 0;
        mode = 2'b10;
        expected_fifo_data = 8'b10101010;
        #970;
        io0_dir = 1;
        io1_dir = 1;
        io2_dir = 1;
        io3_dir = 1;
        @(negedge system_clk)
            begin
                io3_out = 1'b1;
                io2_out = 1'b0;
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        @(negedge system_clk)
            begin
                io3_out = 1'b1;
                io2_out = 1'b0;
                io1_out = 1'b1;
                io0_out = 1'b0;
            end
        wait (write_req == 1);
        io0_dir = 0;
        io1_dir = 0;
        io2_dir = 0;
        io3_dir = 0;
        if    (data_qspi2fifo == expected_fifo_data)
            begin
                $display("Data written to FIFO buffer is correct: %b", data_qspi2fifo);
            end
        else
            begin
                $display("FIFO DATA ERROR!! Expected: %b, Got: %b", expected_fifo_data, data_qspi2fifo);
            end
        wait (read_done == 1);
        $display("quad read operation done");
        
        switch_die = 1;
        #50;
        $display("Switching die operation and read operation");
        read_addr = 32'h000000BB;
        read_flag = 1;

        mode = 2'b00;
        expected_fifo_data = 8'b10101010;
        #1130; //8 * 20ns  for switch die operation
        io0_dir = 1;
        io1_dir = 1;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;
        @(negedge system_clk) io1_out = 1'b1;
        @(negedge system_clk) io1_out = 1'b0;


        wait (write_req == 1);
        io1_dir = 0;
        io0_dir = 0;
        if    (data_qspi2fifo == expected_fifo_data)
            begin
                $display("Data written to FIFO buffer is correct: %b", data_qspi2fifo);
            end
        else
            begin
                $display("FIFO DATA ERROR!! Expected: %b, Got: %b", expected_fifo_data, data_qspi2fifo);
            end
        wait (read_done == 1);
        $display("switch die operation done");

        #100 $stop;
        $display("Testbench done");
    end
endmodule