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

reg    io0_dir, io1_dir, io2_dir, io3_dir;
reg    io0_out, io1_out, io2_out, io3_out;

assign sfr2qspi_io0 = io0_dir ? io0_out : 1'bz;
assign sfr2qspi_io1 = io1_dir ? io1_out : 1'bz;
assign sfr2qspi_io2 = io2_dir ? io2_out : 1'bz;
assign sfr2qspi_io3 = io3_dir ? io3_out : 1'bz;
integer   i;

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
    .switch_die_need(switch_die_need),
    .system_reset_n(system_reset_n),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3)
);

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

        #100;
        system_reset_n = 1;
        
        $display("test1-1: Basic read operation");
        #50;
        start_addr = 32'h00000000;
        end_addr = 32'h00000010;
        mode = 2'b00;
        start_flag = 1;
        for (i = 0; i < 11; i = i + 1)
            begin
                #870;
                io1_dir = 1;
                io0_dir = 1;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;             
                wait(uut.qspi_ctrl4read.write_req == 1);
                io0_dir = 0;
                io1_dir = 0;
                wait(uut.qspi_ctrl4read.read_done == 1);
            end
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test1-2: dual read operation");
        #50;
        start_addr = 32'h00001000;
        end_addr = 32'h00001010;
        mode = 2'b01;
        start_flag = 1;
        for (i = 0; i < 11; i = i + 1)
            begin
                #990;
                io1_dir = 1;
                io0_dir = 1;
                @ (negedge system_clk) 
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                @ (negedge system_clk)
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                @ (negedge system_clk)
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                @ (negedge system_clk)
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end               
                wait(uut.qspi_ctrl4read.write_req == 1);
                io0_dir = 0;
                io1_dir = 0;
                wait(uut.qspi_ctrl4read.read_done == 1);
            end
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test1-3: quad read operation");
        #100;
        start_addr = 32'h00002000;
        end_addr = 32'h00002010;
        mode = 2'b10;
        start_flag = 1;
        for (i = 0; i < 11; i = i + 1)
            begin
                #970;
                io0_dir = 1;
                io1_dir = 1;
                io2_dir = 1;
                io3_dir = 1;
                @ (negedge system_clk) 
                    begin
                        io3_out = 1'b1;
                        io2_out = 1'b0;
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                @ (negedge system_clk) 
                    begin
                        io3_out = 1'b1;
                        io2_out = 1'b0;
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end              
                wait(uut.qspi_ctrl4read.write_req == 1);
                io0_dir = 0;
                io1_dir = 0;
                io2_dir = 0;
                io3_dir = 0;
                wait(uut.qspi_ctrl4read.read_done == 1);
            end
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test2: fifo full operation");
        #100;
        start_addr = 32'h00003000;
        end_addr = 32'h0000300F;
        mode = 2'b00;
        start_flag = 1;
        for (i = 0; i < 16; i = i + 1)
            begin
                if    (i == 8)
                    begin
                        #40;
                        force uut.f1.full = 1'b1;
                        #100;
                        release uut.f1.full;
                    end
                else
                    begin
                        #830;
                        io1_dir = 1;
                        io0_dir = 1;
                        @ (negedge system_clk) io1_out = 1;
                        @ (negedge system_clk) io1_out = 0;
                        @ (negedge system_clk) io1_out = 1;
                        @ (negedge system_clk) io1_out = 0;
                        @ (negedge system_clk) io1_out = 1;
                        @ (negedge system_clk) io1_out = 0;
                        @ (negedge system_clk) io1_out = 1;
                        @ (negedge system_clk) io1_out = 0;                
                        wait(uut.qspi_ctrl4read.write_req == 1);
                        io0_dir = 0;
                        io1_dir = 0;
                        wait(uut.qspi_ctrl4read.read_done == 1);
                    end
            end
        wait(read_finish);
        start_flag = 0;
        #100;

        $display("test3: switch die operation");
        start_addr = 32'h01FFFFF0;
        end_addr = 32'h02000010;
        mode = 2'b00;
        switch_die_need = 1;
        start_flag = 1;
        for (i = 0; i < 17; i = i + 1)
            begin
                #1130;
                io1_dir = 1;
                io0_dir = 1;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;
                @ (negedge system_clk) io1_out = 1;
                @ (negedge system_clk) io1_out = 0;                
                wait(uut.qspi_ctrl4read.write_req == 1);
                io0_dir = 0;
                io1_dir = 0;
                wait(uut.qspi_ctrl4read.read_done == 1);
            end
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
        if    (uut.f1.full)
            begin
                $display("Time %t: FIFO full", $time);
            end
    end
endmodule