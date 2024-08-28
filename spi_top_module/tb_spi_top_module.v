`timescale 1 ns/ 1 ns
module spi_top_module_vlg_tst();

reg CLK_25M_CKMNG_MAIN_PLD;
reg PWRGD_P1V2_MAX10_AUX_PLD_R;

reg [31:0] read_end_addr;
reg [1:0] read_mode;
reg read_req;
reg [31:0] read_start_addr;

reg start_but;
reg switch_die_need;
wire busy_n;
wire completed_n;

wire    roma_io0, roma_io1, roma_io2, roma_io3;
reg    io0_dir, io1_dir, io2_dir, io3_dir;
reg    io0_out, io1_out, io2_out, io3_out;

wire    romb_io0, romb_io1, romb_io2, romb_io3;

assign roma_io0 = io0_dir ? io0_out : 1'bz;
assign roma_io1 = io1_dir ? io1_out : 1'bz;
assign roma_io2 = io2_dir ? io2_out : 1'bz;
assign roma_io3 = io3_dir ? io3_out : 1'bz;

reg    write_mode;
reg    [31:0] write_start_addr;
// wires


wire    read_cs_n;
wire    read_spi_clk;
wire    [15:0] rom_data_num;
wire    [7:0] roma_data;

wire    write_cs_n;
wire    write_spi_clk;

wire    start_signal;

wire    BMC_SEL;
wire    PCH_SEL;
wire    SKT3_OE_CTL;

// assign statements (if any)                          

integer i;

spi_top_module uut(
// port map - connection between master ports and signals/registers   
 .BMC_SEL(BMC_SEL),
 .CLK_25M_CKMNG_MAIN_PLD(CLK_25M_CKMNG_MAIN_PLD),
 .PCH_SEL(PCH_SEL),
 .PWRGD_P1V2_MAX10_AUX_PLD_R(PWRGD_P1V2_MAX10_AUX_PLD_R),
 .SKT3_OE_CTL(SKT3_OE_CTL),
 .busy_n(busy_n),
 .completed_n(completed_n),
 .roma_data(roma_data),
 .read_cs_n(read_cs_n),
 .read_end_addr(read_end_addr),
 .read_mode(read_mode),
 .read_req(read_req),
 .read_spi_clk(read_spi_clk),
 .read_start_addr(read_start_addr),
 .roma_io0(roma_io0),
 .roma_io1(roma_io1),
 .roma_io2(roma_io2),
 .roma_io3(roma_io3),
 .romb_io0(romb_io0),
 .romb_io1(romb_io1),
 .romb_io2(romb_io2),
 .romb_io3(romb_io3),
 .start_but(start_but),
 .switch_die_need(switch_die_need),
 .write_cs_n(write_cs_n),
 .write_mode(write_mode),
 .write_spi_clk(write_spi_clk),
 .write_start_addr(write_start_addr),
 .start_signal(start_signal)
);

// Clock generation
always #20 CLK_25M_CKMNG_MAIN_PLD = ~CLK_25M_CKMNG_MAIN_PLD;

initial
    begin
        $display("Running testbench");
        CLK_25M_CKMNG_MAIN_PLD = 1'b0;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;
        start_but = 1'b0;
        read_start_addr = 32'h00000000;
        read_end_addr = 32'h00000000;
        switch_die_need = 1'b0;
        read_mode = 2'b00;
        write_start_addr = 32'h00000000;
        write_mode = 1'b0;
        read_req = 1'b0;
        io0_dir = 1'b0;
        io1_dir = 1'b0;
        io2_dir = 1'b0;
        io3_dir = 1'b0;
        io0_out = 1'b0;
        io1_out = 1'b0;
        io2_out = 1'b0;
        io3_out = 1'b0;

        #200;
        PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b1;
        #200;


        read_start_addr = 32'h00000000;
        read_end_addr = 32'h0000000B;
        read_mode = 2'b00;
        switch_die_need = 1'b0;
        start_but = 1'b1;
        #20 start_but = 1'b0;

        write_start_addr = 32'h00000000;
        write_mode = 1'b0;
        #100 force uut.k1.key_flag = 1'b1;
        wait(uut.k1.key_flag == 1);
        release uut.k1.key_flag;
        #3210;
        io1_dir = 1'b1;
        io0_dir = 1'b0;
        repeat (12)
            begin
                @ (negedge read_spi_clk) io1_out = 1;
                @ (negedge read_spi_clk) io1_out = 0;
                @ (negedge read_spi_clk) io1_out = 1;
                @ (negedge read_spi_clk) io1_out = 0;
                @ (negedge read_spi_clk) io1_out = 1;
                @ (negedge read_spi_clk) io1_out = 0;
                @ (negedge read_spi_clk) io1_out = 1;
                @ (negedge read_spi_clk) io1_out = 0;
                read_req = 1'b1;
            end
        wait (uut.r1.read_finish == 1);
        io0_dir = 1'b0;
        io1_dir = 1'b0;


        wait (completed_n == 1);
        #100 PWRGD_P1V2_MAX10_AUX_PLD_R = 1'b0;

        $display("Testbench completed");
        $display("Number of bytes transferred : %d", rom_data_num);

        #1000 $finish;                           
    end
endmodule