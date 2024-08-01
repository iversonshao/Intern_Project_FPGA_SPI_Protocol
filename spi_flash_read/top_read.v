module top_read (
    input wire    CLK_25M_CKMNG_MAIN_PLD,
    input wire    PWRGD_P1V2_MAX10_AUX_PLD_R,
    // input wire    start_flag,
    input wire    [31:0] start_addr,
    input wire    [31:0] end_addr,
    input wire    [2:0] mode,
    input wire    read_req,
    input wire    switch_die_need,
    output wire    busy, //spi bus is occupied(1=yes, 0=no)
    output wire    completed, //spi rom image copy is completed(1=yes, 0=no)
    inout wire    sfr2qspi_io0,    // SPI flash read data I/O 0
    inout wire    sfr2qspi_io1,    // SPI flash read data I/O 1
    inout wire    sfr2qspi_io2,    // SPI flash read data I/O 2
    inout wire    sfr2qspi_io3,   // SPI flash read data I/O 3
    output wire    spi_clk,
    output wire    spi_cs_n,
    output wire    BMC_SEL,
    output wire    PCH_SEL
);

wire    read_finish;
wire    system_clk;
wire    system_reset_n;
reg    start_flag;

reg    [7:0] counter;
reg    start_flag_en;
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
    .system_reset_n(system_reset_n),
    .sfr2qspi_io0(sfr2qspi_io0),
    .sfr2qspi_io1(sfr2qspi_io1),
    .sfr2qspi_io2(sfr2qspi_io2),
    .sfr2qspi_io3(sfr2qspi_io3),
    .spi_clk(spi_clk),
    .spi_cs_n(spi_cs_n)
    
);

assign busy = ~read_finish;
assign completed = read_finish;
assign BMC_SEL = 1'b1;
assign PCH_SEL = 1'b1;

always @(posedge system_clk or negedge system_reset_n)
    begin
        if (!system_reset_n)
            begin
                counter <= 8'd0;
                start_flag_en <= 1'b0;
            end
        else
            begin
                if    (completed || (busy && !completed))
                    begin
                        if    (counter == 8'd10)
                            begin
                                start_flag_en <= 1'b1;
                                counter <= 8'd0;
                            end
                        else
                            begin
                                start_flag_en <= 1'b0;
                                counter <= counter + 1'b1;
                            end
                    end
                else
                    begin
                        start_flag_en <= 1'b0;
                        counter <= 8'd0;
                    end
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                start_flag <= 1'b0;
            end
        else
            begin
                if    (completed)
                    begin
                        start_flag <= 1'b0;
                    end
                else
                    begin
                        start_flag <= start_flag_en || busy;
                    end
            end
    end

endmodule