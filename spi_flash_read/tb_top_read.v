`timescale 1 ns/ 1 ns

module top_read_vlg_tst();

reg    CLK_25M_CKMNG_MAIN_PLD;
reg    PWRGD_P1V2_MAX10_AUX_PLD_R;

reg    [31:0] end_addr;
reg    [1:0] mode;
reg    read_req;
reg    [31:0] start_addr;
reg    start_but;
reg    switch_die_need;
wire    busy;
wire    completed;
wire    spi_clk;
wire    cs_n;
wire    [7:0] fifo_output;
wire    [15:0] rom_data_num;

wire    sfr2qspi_io0, sfr2qspi_io1, sfr2qspi_io2, sfr2qspi_io3;
reg    io0_dir, io1_dir, io2_dir, io3_dir;
reg    io0_out, io1_out, io2_out, io3_out;


assign sfr2qspi_io0 = io0_dir ? io0_out : 1'bz;
assign sfr2qspi_io1 = io1_dir ? io1_out : 1'bz;
assign sfr2qspi_io2 = io2_dir ? io2_out : 1'bz;
assign sfr2qspi_io3 = io3_dir ? io3_out : 1'bz;
top_read uut (
    .PWRGD_P1V2_MAX10_AUX_PLD_R(PWRGD_P1V2_MAX10_AUX_PLD_R),
    .start_addr(start_addr),
    .end_addr(end_addr),
    .busy(busy),
    .completed(completed),
    .CLK_25M_CKMNG_MAIN_PLD(CLK_25M_CKMNG_MAIN_PLD),
    .mode(mode),
    .read_req(read_req),
    .start_but(start_but),
    .switch_die_need(switch_die_need),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3),
    .spi_clk(spi_clk),
    .cs_n(cs_n),
    .BMC_SEL(),
    .PCH_SEL(),
    .clk100(),
    .rom_data_num(rom_data_num),
    .fifo_output(fifo_output)
);

always #20 CLK_25M_CKMNG_MAIN_PLD = ~CLK_25M_CKMNG_MAIN_PLD; // 25MHz

initial 
    begin
        CLK_25M_CKMNG_MAIN_PLD = 1'b0;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;
        end_addr = 32'h00000000;
        mode = 2'b00;
        read_req = 1'b0;
        start_addr = 32'h00000000;
        switch_die_need = 1'b0;
        start_but = 1'b0;
        io0_dir = 1'b0;
        io1_dir = 1'b0;
        io2_dir = 1'b0;
        io3_dir = 1'b0;
        io0_out = 1'b0;
        io1_out = 1'b0;
        io2_out = 1'b0;
        io3_out = 1'b0;

        #100;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b1;
        $display("Test 1: Standard mode read");

        #100;
        start_addr = 32'h00000000;
        end_addr = 32'h0000000B;
        mode = 2'b00;
        switch_die_need = 1'b0;
        start_but = 1'b1;
        #20 start_but = 1'b0;
        #100force uut.k1.key_flag = 1'b1;
        wait(uut.k1.key_flag == 1);
        release uut.k1.key_flag;
        #3210;
        io1_dir = 1;
        io0_dir = 0;
        repeat (12)
            begin
                @ (negedge spi_clk) io1_out = 1;
                @ (negedge spi_clk) io1_out = 0;
                @ (negedge spi_clk) io1_out = 1;
                @ (negedge spi_clk) io1_out = 0;
                @ (negedge spi_clk) io1_out = 1;
                @ (negedge spi_clk) io1_out = 0;
                @ (negedge spi_clk) io1_out = 1;
                @ (negedge spi_clk) io1_out = 0;             
                read_req = 1'b1;
                #40 read_req = 1'b0;
            end
        wait(uut.s1.qspi_ctrl4read.read_done);
        io0_dir = 0;
        io1_dir = 0;

        wait(completed);
        #100 PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;
        #100;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b1;
        $display("Test 2: Dual mode read");
        #100;
        start_addr = 32'h00001000;
        end_addr = 32'h0000100B;
        mode = 2'b01;
        switch_die_need = 1'b0;
        start_but = 1'b1;
        #20 start_but = 1'b0;
        #100force uut.k1.key_flag = 1'b1;
        wait(uut.k1.key_flag == 1);
        release uut.k1.key_flag;
        #3820;
        io1_dir = 1;
        io0_dir = 1;
        repeat (12)
            begin
                @ (negedge spi_clk) 
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b1;
                    end
                @ (negedge spi_clk) 
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                @ (negedge spi_clk) 
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b1;
                    end
                @ (negedge spi_clk) 
                    begin
                        io1_out = 1'b1;
                        io0_out = 1'b0;
                    end
                read_req = 1'b1;
                #40 read_req = 1'b0;
            end

        wait(uut.s1.qspi_ctrl4read.read_done == 1);
        io0_dir = 0;
        io1_dir = 0;
        wait(completed);
        #100;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;
        #100 PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b1;

        $display("Test 3: Quad mode read");
        #100;
        start_addr = 32'h00002000;
        end_addr = 32'h0000200B;
        mode = 2'b10;
        switch_die_need = 1'b0;
        start_but = 1'b1;
        #20 start_but = 1'b0;
        #100force uut.k1.key_flag = 1'b1;
        wait(uut.k1.key_flag == 1);
        release uut.k1.key_flag;
        #3820;
        io0_dir = 1;
        io1_dir = 1;
        io2_dir = 1;
        io3_dir = 1;
        repeat (12)
            begin
                @ (negedge spi_clk) 
                    begin
                        io3_out = 1'b1;
                        io2_out = 1'b0;
                        io1_out = 1'b1;
                        io0_out = 1'b1;
                    end
                @ (negedge spi_clk) 
                    begin
                        io3_out = 1'b1;
                        io2_out = 1'b1;
                        io1_out = 1'b0;
                        io0_out = 1'b1;
                    end
                read_req = 1'b1;
                #40 read_req = 1'b0;
            end
        wait(uut.s1.qspi_ctrl4read.read_done == 1);
        io0_dir = 0;
        io1_dir = 0;
        io2_dir = 0;
        io3_dir = 0;
        wait(completed);
        #100;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;
        // #100 PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b1;
        // #100;

        // $display("Test 4: FIFO full test");
        // #50;
        // start_addr = 32'h00000300;
        // end_addr = 32'h0000030F;
        // mode = 2'b00;
        // start_flag = 1'b1;
        // for (i = 0; i < 16; i = i + 1)
        //     begin
        //         if    (i == 8)
        //             begin
        //                 force uut.s1.f1.full = 1'b1;
        //                 #200;
        //                 release uut.s1.f1.full;
        //                 #870;
        //                 io1_dir = 1;
        //                 io0_dir = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;               
        //                 #40;
        //                 io0_dir = 0;
        //                 io1_dir = 0;
        //                 wait(uut.s1.qspi_ctrl4read.read_done == 1);
        //             end
        //         else
        //             begin
        //                 #850;
        //                 io1_dir = 1;
        //                 io0_dir = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;                
        //                 #40;
        //                 io0_dir = 0;
        //                 io1_dir = 0;
        //                 wait(uut.s1.qspi_ctrl4read.read_done == 1);
        //             end
        //     end
        // wait(completed);
        // start_flag = 1'b0;
        // #100;

        // $display("Test 5: Die switch");
        // #100;
        // start_addr = 32'h01FFFFF0;
        // end_addr = 32'h02000010;
        // mode = 2'b00;
        // switch_die_need = 1;
        // start_flag = 1'b1;
        // for (i = 0; i < 33; i = i + 1)
        //     begin
        //         if    (i == 16)
        //             begin
        //                 #1100;
        //                 io1_dir = 1;
        //                 io0_dir = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 #40;
        //                 io0_dir = 0;
        //                 io1_dir = 0;
        //                 wait(uut.s1.qspi_ctrl4read.read_done == 1);
        //             end
        //         else
        //             begin
        //                 #850;
        //                 io1_dir = 1;
        //                 io0_dir = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;
        //                 @ (negedge uut.s1.system_clk) io1_out = 1;
        //                 @ (negedge uut.s1.system_clk) io1_out = 0;                
        //                 #40;
        //                 io0_dir = 0;
        //                 io1_dir = 0;
        //                 wait(uut.s1.qspi_ctrl4read.read_done == 1);
        //             end
        //     end
        // wait(completed);
        // switch_die_need = 0;
        // start_flag = 1'b0;
        // #100;

        $display("All tests completed");
        $stop;
    end

always @(posedge CLK_25M_CKMNG_MAIN_PLD) 
    begin
        if    (uut.s1.read_finish) $display("Time %t: Read finish", $time);
        if    (!uut.s1.system_reset_n) $display("Time %t: Reset", $time);
        if    (busy) $display("Time %t: Busy", $time);
        if    (completed) $display("Time %t: Completed", $time);
    end

endmodule