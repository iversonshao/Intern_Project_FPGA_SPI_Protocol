module top_read (
    input wire    CLK_25M_CKMNG_MAIN_PLD,
    input wire    PWRGD_P1V2_MAX10_AUX_PLD_R,
    input wire    start_flag,
    input wire    [31:0] start_addr,
    input wire    [31:0] end_addr,
    input wire    [1:0] mode,
    input wire    read_req,
    input wire    switch_die_need,
    output wire    busy, //spi bus is occupied(1=yes, 0=no)
    output wire    completed //spi rom image copy is completed(1=yes, 0=no)
);

wire    system_clk;
wire    system_reset_n;

pll p1 (
 .areset(PWRGD_P1V2_MAX10_AUX_PLD_R),
 .inclk0(CLK_25M_CKMNG_MAIN_PLD),
 .c0(system_clk),
 .locked(system_reset_n)
);


spi_flash_read s1 (
    .start_addr(start_addr),
    .end_addr(end_addr),
    .mode(mode),
    .switch_die_need(switch_die_need),
    .read_finish(read_finish),
    .read_req(read_req),
    .start_flag(start_flag),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n)
);

assign busy = read_finish ? 0 : 1;
assign completed = busy ? 0 : 1;


endmodule