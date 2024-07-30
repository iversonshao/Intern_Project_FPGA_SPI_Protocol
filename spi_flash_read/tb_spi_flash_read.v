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
// wires                                               
wire    read_finish;
reg    fifo_full;

// assign statements (if any)                          
spi_flash_read uut (
// port map - connection between master ports and signals/registers   
    .end_addr(end_addr),
    .mode(mode),
    .read_finish(read_finish),
    .read_req(read_req),
    .start_addr(start_addr),
    .start_flag(start_flag),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n)
);


always #20 system_clk = ~system_clk;

initial
    begin
        $display("Running testbench");
        system_reset_n <= 0;
        system_clk = 0;
        start_flag = 0;
        start_addr = 32'h00000000;
        end_addr = 32'h00000000;
        mode = 2'b00;
        read_req = 0;

        #100;
        system_reset_n <= 1;
        
        $display("test1: Basic read operation");
        #100;
        start_addr = 32'h00000000;
        end_addr = 32'h00000010;
        start_flag = 1;
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test2: fifo full operation");
        #100;
        start_addr = 32'h00001000;
        end_addr = 32'h0000100F;
        start_flag = 1;
        #40;
        fifo_full = 1;
        #20;
        fifo_full = 0;
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test3: switch die operation");
        start_addr = 32'h01FFFFF0;
        end_addr = 32'h02000010;
        start_flag = 1;
        wait(read_finish);
        start_flag = 0;
        #1000 $stop;
    end

always @(posedge system_clk)
    begin
        if    (uut.state != uut.next_state)
            begin
                $display("Time %t: state change from %d to %d", $time, uut.state, uut.next_state);
            end
        if    (uut.sw)
            begin
                $display("Time %t: Switching die", $time);
            end
    end
endmodule