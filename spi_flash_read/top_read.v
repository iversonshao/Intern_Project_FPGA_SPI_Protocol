module top_read (
    input wire    CLK_25M_CKMNG_MAIN_PLD,
    input wire    PWRGD_P1V2_MAX10_AUX_PLD_R,
    input wire    start_but,
    input wire    [31:0] start_addr,
    input wire    [31:0] end_addr,
    input wire    [1:0] mode,
    input wire    read_req,
    input wire    switch_die_need,
    output reg    busy_n, //spi bus is occupied
    output reg    completed_n, //spi rom image copy is completed
    inout wire    sfr2qspi_io0,    // SPI flash read data I/O 0
    inout wire    sfr2qspi_io1,    // SPI flash read data I/O 1
    inout wire    sfr2qspi_io2,    // SPI flash read data I/O 2
    inout wire    sfr2qspi_io3,   // SPI flash read data I/O 3
    output wire    romaspi_clk,
    output wire    romacs_n,
    output reg    BMC_SEL,
    output reg    PCH_SEL,
    output reg    SKT3_OE_CTL,
	output wire    [7:0] fifo_output
);

parameter READ_MODE = 2'b00;
parameter ROM_A_START_ADDR = 32'h00000000;
parameter ROM_A_END_ADDR = 32'h029B4FF0;

wire    start_signal;
wire    read_start_signal;

wire    system_clk;
wire    system_reset_n;
wire    read_finish;

wire    full;
wire    [31:0] roma_data_num;



pll p1 (
 .areset(!PWRGD_P1V2_MAX10_AUX_PLD_R),
 .inclk0(CLK_25M_CKMNG_MAIN_PLD),
 .c0(system_clk),
 .c1(clk100),
 .locked(system_reset_n)
);

key_filter k1(
    .system_clk(system_clk),
    .key_in(start_but),
    .key_flag(start_signal)
);

spi_flash_read s1 (
    .start_addr(ROM_A_START_ADDR),
    .end_addr(ROM_A_END_ADDR),
    .mode(READ_MODE),
    .switch_die_need(1'b0),
    .read_finish(read_finish),
    .spi_read_req(1'b1), //1'b1;
    .start_flag(read_start_signal),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3),
    .spi_clk(romaspi_clk),
    .cs_n(romacs_n),
    .rom_data_num(roma_data_num),
    .fifo_output(fifo_output),
    .full(full),
	.empty(empty)
);


assign read_start_signal = start_signal ? 1'b1 : 1'b0;

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                PCH_SEL <= 1'b0;
                BMC_SEL <= 1'b0;
                SKT3_OE_CTL <= 1'b0;
                busy_n <= 1'b1;
                completed_n <= 1'b1;
            end
        else if    (start_signal)
            begin
                PCH_SEL <= 1'b1;
                BMC_SEL <= 1'b1;
                SKT3_OE_CTL <= 1'b1;
                busy_n <= 1'b0;
            end
        else if    (full)
            begin
                PCH_SEL <= 1'b0;
                BMC_SEL <= 1'b0;
                busy_n <= 1'b1;
                completed_n <= 1'b0;
            end
        else if    (read_finish)
            begin
                PCH_SEL <= 1'b0;
                BMC_SEL <= 1'b0;
                SKT3_OE_CTL <= 1'b0;
                busy_n <= 1'b1;
                completed_n <= 1'b0;
            end
    end
endmodule