module top_read (
    input wire    CLK_25M_CKMNG_MAIN_PLD,
    input wire    PWRGD_P1V2_MAX10_AUX_PLD_R,
    input wire    start_but,
    // input wire    [31:0] start_addr,
    // input wire    [31:0] end_addr,
    // input wire    [1:0] mode,
    input wire    read_req,
    input wire    switch_die_need,
    output wire    busy, //spi bus is occupied
    output wire    completed, //spi rom image copy is completed
    inout wire    sfr2qspi_io0,    // SPI flash read data I/O 0
    inout wire    sfr2qspi_io1,    // SPI flash read data I/O 1
    inout wire    sfr2qspi_io2,    // SPI flash read data I/O 2
    inout wire    sfr2qspi_io3,   // SPI flash read data I/O 3
    output wire    spi_clk,
    output wire    spi_cs_n,
    output wire    BMC_SEL,
    output wire    PCH_SEL,
    output wire    c1
);
wire    start_flag;

pll p1 (
 .areset(!PWRGD_P1V2_MAX10_AUX_PLD_R),
 .inclk0(CLK_25M_CKMNG_MAIN_PLD),
 .c0(c0),
 .c1(c1),
 .locked(locked)
);

key_filter #(
    .CNT_MAX (CNT_MAX)
) k1 (
    .system_clk(c0),
    .system_reset_n(locked),
    .key_in(start_but),
    .key_flag(start_flag)
);

spi_flash_read s1 (
    .start_addr(32'h00000000),
    .end_addr(32'h029B4FF0),
    .mode(2'b00),
    .switch_die_need(1'b0),
    .read_finish(read_finish),
    .spi_read_req(1'b1),
    .start_flag(start_flag),
    .system_clk(c0),
    .system_reset_n(locked),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3),
    .spi_clk(spi_clk),
    .spi_cs_n(spi_cs_n)
    
);
//mode 00 = standard 01 = dual 10 = quad

assign BMC_SEL = 1'b1;
assign PCH_SEL = 1'b1;

assign busy = read_finish? 1'b0 : 1'b1;
assign completed = read_finish? 1'b1 : 1'b0;
endmodule