module spi_top_module (
    input wire    CLK_25M_CKMNG_MAIN_PLD,
    input wire    PWRGD_P1V2_MAX10_AUX_PLD_R,
    input wire    start_but,
    input wire    [31:0] read_start_addr,
    input wire    [31:0] read_end_addr,
    input wire    [31:0] write_start_addr,
    input wire    [1:0] read_mode,
    input wire    write_mode,
    input wire    read_req, //write to ROMB
    input wire    switch_die_need,
    output reg    busy_n, //spi bus is occupied
    output reg    completed_n, //spi rom image copy is completed
    inout wire    roma_io0,   // SPI flash read data I/O 0
    inout wire    roma_io1,   // SPI flash read data I/O 1
    inout wire    roma_io2,   // SPI flash read data I/O 2
    inout wire    roma_io3,   // SPI flash read data I/O 3
    inout wire    romb_io0,   // SPI flash write data I/O 0
    inout wire    romb_io1,   // SPI flash write data I/O 1 
    inout wire    romb_io2,   // SPI flash write data I/O 2
    inout wire    romb_io3,   // SPI flash write data I/O 3
	output wire    [7:0] roma_data,
    output wire    read_spi_clk,
    output wire    read_cs_n,
    output wire    write_spi_clk,
    output wire    write_cs_n,
    output wire    start_signal,
    output reg    BMC_SEL,
    output reg    PCH_SEL,
    output reg    SKT3_OE_CTL
);

parameter READ_MODE = 2'b00;
parameter WRITE_MODE = 1'b0;
parameter ROM_A_START_ADDR = 32'h01000F00;
parameter ROM_A_END_ADDR = 32'h01000F05;
parameter ROM_B_START_ADDR = 32'h03000000;

wire    read_start_signal;
// wire    start_signal;

wire    system_clk;
wire    system_reset_n;
wire    clk100;

wire    read_finish;
wire    write_start_signal;
wire    se_done;
wire    pp_done;

wire    [31:0] rom_data_num;

assign read_start_signal = start_signal;
assign write_start_signal = start_signal;
//set
// assign read_start_addr = 32'h01000F00;
// assign read_end_addr = 32'h02000EFF;
// assign write_start_addr = 32'h03000000;
// assign read_mode = 2'b00;
// assign write_mode = 1'b0;
// assign switch_die_need = 1'b0;
// assign read_req = 1'b1;

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

spi_flash_read r1 (
    .start_addr(ROM_A_START_ADDR),
    .end_addr(ROM_A_END_ADDR),
    .mode(READ_MODE),
    .switch_die_need(1'b0),
    .read_finish(read_finish),
    .spi_read_req(1'b1),
    .start_flag(read_start_signal),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .sfr2qspi_io0(roma_io0),
    .sfr2qspi_io1(roma_io1),
    .sfr2qspi_io2(roma_io2),
    .sfr2qspi_io3(roma_io3),
    .spi_clk(read_spi_clk),
    .cs_n(read_cs_n),
    .rom_data_num(rom_data_num),
    .fifo_output(roma_data),
    .full(),
    .empty()
);

spi_flash_write w1 (
    .cs_n(write_cs_n),
    .io0(romb_io0),
    .io1(romb_io1),
    .io2(romb_io2),
    .io3(romb_io3),
    .mode(WRITE_MODE),
    .pi_flag(write_start_signal),
    .pp_done(pp_done),
    .se_done(se_done),
    .spi_clk(write_spi_clk),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .write_data(roma_data),
    .write_finish(write_finish),
    .write_num(rom_data_num),
    .write_start_addr(ROM_B_START_ADDR)
);

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
        else if    (read_finish)
            begin
                PCH_SEL <= 1'b1;
                BMC_SEL <= 1'b1;
                SKT3_OE_CTL <= 1'b1;
                busy_n <= 1'b0;
                completed_n <= 1'b1;
            end
        else if    (write_finish)
            begin
                PCH_SEL <= 1'b0;
                BMC_SEL <= 1'b0;
                SKT3_OE_CTL <= 1'b0;
                busy_n <= 1'b1;
                completed_n <= 1'b0;
            end
    end
endmodule