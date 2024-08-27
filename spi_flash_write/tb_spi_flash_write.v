`timescale 1 ns/ 1 ns
module spi_flash_write_vlg_tst();


parameter CLK_PERIOD = 20;
parameter ROM = 8192;
reg    pi_flag;
reg    system_clk;
reg    system_reset_n;
reg    [7:0] write_data;
reg    [15:0] write_num;
reg    [31:0] write_start_addr;
reg    mode;
// wires                                               
wire    cs_n;
wire    io0;
wire    io1;
wire    io2;
wire    io3;
wire    pp_done;
wire    se_done;
wire    spi_clk;
wire    write_finish;


// assign statements (if any)                          
spi_flash_write uut (
// port map - connection between master ports and signals/registers   
 .cs_n(cs_n),
 .io0(io0),
 .io1(io1),
 .io2(io2),
 .io3(io3),
 .mode(mode),
 .pi_flag(pi_flag),
 .pp_done(pp_done),
 .se_done(se_done),
 .spi_clk(spi_clk),
 .system_clk(system_clk),
 .system_reset_n(system_reset_n),
 .write_data(write_data),
 .write_finish(write_finish),
 .write_num(write_num),
 .write_start_addr(write_start_addr)
);

integer i;
always
    begin
        #(CLK_PERIOD/2) system_clk = ~system_clk;
    end

initial
    begin
        system_reset_n = 0;
        system_clk = 0;
        pi_flag = 0;
        write_num = 16'd0;
        write_start_addr = 32'h0000_0000;
        write_data = 8'h00;
        write_num = 16'd0;
        mode = 0;


        #200 system_reset_n = 1;
        //case1:write 512B (need 1se)
        #200;
        write_start_addr = 32'h0000_0000;
        write_num = 16'd512;
        pi_flag = 1;
        #40 pi_flag = 0;
        mode = 0;

        for (i = 0; i < 512; i = i + 1)
            begin
                write_data = i[7:0];
                @(posedge system_clk);
            end
        
        wait(write_finish);
        system_reset_n = 0;
        #1000;

        #200 system_reset_n = 1;
        //case2:write 5KB (need 2se)
        #200;
        write_start_addr = 32'h0000_1000;
        write_num = 16'd5120;
        pi_flag = 1;
        #40 pi_flag = 0;
        mode = 0;
        
        for (i = 0; i < 5120; i = i + 1)
            begin
                write_data = (i * 2) & 8'hFF;
                @(posedge system_clk);
            end
        wait(write_finish);
        system_reset_n = 0;

        #1000;

        #200 system_reset_n = 1;
        //case3:write 2KB in PPX4 mode (need 1se)
        #200;
        write_start_addr = 32'h0000_2000;
        write_num = 16'd2048;
        pi_flag = 1;
        #40 pi_flag = 0;
        mode = 1;

        for (i = 0; i < 2048; i = i + 1)
            begin
                write_data = (i * 3) & 8'hFF;
                @(posedge system_clk);
            end
        wait(write_finish);
        system_reset_n = 0;

        #10000;
        $finish;

    end

always @(posedge system_clk)
    begin
        if    (se_done)
            begin
                $display("Sector Erase done at time %t", $time);
            end
        if    (pp_done)
            begin
                $display("Page Program done at time %t", $time);
            end
        if    (write_finish)
            begin
                $display("Write finish at time %t", $time);
            end
    end

real    tse_time;
always @(posedge se_done)
    begin
        tse_time = $realtime;
    end

always @(posedge pp_done)
    begin
        if    ($realtime - tse_time < 60)
            begin
                $display("Warning: TSE time not respected. Time since last SE: %0t", $realtime - tse_time);
            end
    end
endmodule