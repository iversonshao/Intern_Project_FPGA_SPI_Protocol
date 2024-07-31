`timescale 1 ns / 1 ns

module spi_flash_read_vlg_tst();
    // Constants and test vector input registers
    reg    [31:0] start_addr;
    reg    [31:0] end_addr;
    reg    [1:0] mode;
    reg    read_req;
    reg    start_flag;
    reg    system_clk;
    reg    system_reset_n;
    reg    switch_die_need;

    // Wires
    wire    read_finish;
    wire    sfr2qspi_io0, sfr2qspi_io1, sfr2qspi_io2, sfr2qspi_io3;

    // Bidirectional pin control
    reg    io0_dir, io1_dir, io2_dir, io3_dir;
    reg    io0_out, io1_out, io2_out, io3_out;

    // Bidirectional port assignments
    assign sfr2qspi_io0 = io0_dir ? io0_out : 1'bz;
    assign sfr2qspi_io1 = io1_dir ? io1_out : 1'bz;
    assign sfr2qspi_io2 = io2_dir ? io2_out : 1'bz;
    assign sfr2qspi_io3 = io3_dir ? io3_out : 1'bz;

    // Instantiate the Unit Under Test (UUT)
    spi_flash_read uut (
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

    // Clock generation
    always #10 system_clk = ~system_clk;

    initial 
        begin
            // Initialize inputs
            system_clk = 0;
            system_reset_n = 0;
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

            // Reset sequence
            #100 system_reset_n = 1;

            #50 $display("Running testbench");

            // Test case 1: Standard read operation
            $display("Test 1: Standard read operation");
            start_addr = 32'h000000BB;
            end_addr = 32'h000000BE;  // Read 4 bytes
            mode = 2'b00;
            start_flag = 1;
            simulate_multiple_reads(4, 2'b00);
            wait(read_finish);
            start_flag = 0;
            #50;

            // Test case 2: Dual read operation
            $display("Test 2: Dual read operation");
            start_addr = 32'h000000AA;
            end_addr = 32'h000000AD;  // Read 4 bytes
            mode = 2'b01;
            start_flag = 1;
            simulate_multiple_reads(4, 2'b01);
            wait(read_finish);
            start_flag = 0;
            #50;

            // Test case 3: Quad read operation
            $display("Test 3: Quad read operation");
            start_addr = 32'h000000CC;
            end_addr = 32'h000000CF;  // Read 4 bytes
            mode = 2'b10;
            start_flag = 1;
            simulate_multiple_reads(4, 2'b10);
            wait(read_finish);
            start_flag = 0;
            #50;

            // Test case 4: Switch die operation
            $display("Test 4: Switch die operation");
            start_addr = 32'h01FFFFF0;
            end_addr = 32'h02000003;  // Read across die boundary
            mode = 2'b00;
            switch_die_need = 1;
            start_flag = 1;
            #160;
            simulate_multiple_reads(20, 2'b00);  // Simulate more reads to cover die switch
            wait(read_finish);
            start_flag = 0;
            switch_die_need = 0;

            // End simulation
            #100 $stop;
            $display("Testbench completed");
    end

    // Task to simulate multiple SPI flash reads
    task simulate_multiple_reads;
        input integer     num_reads;
        input     [1:0] current_mode;
        integer     i;
        begin
            for (i = 0; i < num_reads; i = i + 1) 
                begin
					     wait(uut.qspi_ctrl4read.read_flag == 1);
                    simulate_spi_response(8'b10101010 + i, current_mode);  // Vary data for each read
						  wait(uut.qspi_ctrl4read.read_flag == 1);
						  #20;
                end
        end
    endtask

    // Task to simulate SPI flash response
    task simulate_spi_response;
        input    [7:0] data;
        input    [1:0] current_mode;
        integer     i;
        begin
            case (current_mode)
                2'b00: 
                    begin // Standard mode
                        #870;
                        io0_dir = 1;
                        io1_dir = 1;
                        for (i = 7; i >= 0; i = i - 1) 
                            begin
                                @(negedge system_clk) io1_out = data[i];
                            end
								@(posedge uut.qspi_ctrl4read.spi_clk);
								wait(uut.qspi_ctrl4read.write_req == 1);
                        #2 io1_dir = 0;
                        io0_dir = 0;
                    end
                2'b01: 
                    begin // Dual mode
                        #990;
                        io0_dir = 1;
                        io1_dir = 1;
                        for (i = 6; i >= 0; i = i - 2) 
                            begin
                                @(negedge system_clk)
                                begin
                                    io1_out = data[i+1];
                                    io0_out = data[i];
                                end
                            end
							   @(posedge uut.qspi_ctrl4read.spi_clk);
								wait(uut.qspi_ctrl4read.write_req == 1);
                        #2 io0_dir = 0;
                        io1_dir = 0;
                    end
                2'b10: 
                    begin // Quad mode
                        #990;
                        io0_dir = 1;
                        io1_dir = 1;
                        io2_dir = 1;
                        io3_dir = 1;
                        for (i = 4; i >= 0; i = i - 4) 
                            begin
                            @(negedge system_clk)
                                begin
                                    io3_out = data[i+3];
                                    io2_out = data[i+2];
                                    io1_out = data[i+1];
                                    io0_out = data[i];
                                end
                            end
								@(posedge uut.qspi_ctrl4read.spi_clk);
								wait(uut.qspi_ctrl4read.write_req == 1);
                        #2 io0_dir = 0;
                        io1_dir = 0;
                        io2_dir = 0;
                        io3_dir = 0;
                    end
            endcase
        end
    endtask

    // Monitor state changes and important events
    always @(posedge system_clk) 
        begin
            if (uut.state != uut.next_state)
                begin
                    $display("Time %t: State change from %d to %d", $time, uut.state, uut.next_state);
                end
            if (uut.sw)
                begin
                    $display("Time %t: Switching die", $time);
                end
            if (uut.f1.full)
                begin
                    $display("Time %t: FIFO full", $time);
                end
        end

endmodule