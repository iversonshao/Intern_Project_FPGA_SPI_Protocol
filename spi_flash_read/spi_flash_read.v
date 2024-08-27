module spi_flash_read(
    input wire    system_clk,       // System clock input
    input wire    system_reset_n,          // Active low reset input
    input wire    start_flag, //pi_key,            // Start signal input
    input wire    [31:0] start_addr, // Start address input (32 bits for flexibility)
    input wire    [31:0] end_addr,   // End address input (32 bits for flexibility)
    input wire    [1:0] mode,            // Mode input (0: Single, 1: Dual, 2: Quad)
    input wire    spi_read_req,       // Read request signal input
    input wire    switch_die_need,
    inout wire    sfr2qspi_io0,    // SPI flash read data I/O 0
    inout wire    sfr2qspi_io1,    // SPI flash read data I/O 1
    inout wire    sfr2qspi_io2,    // SPI flash read data I/O 2
    inout wire    sfr2qspi_io3,    // SPI flash read data I/O 3
    output reg    read_finish,          // Read finish signal output
    output    cs_n,
    output    spi_clk,
    output reg    [31:0] rom_data_num,
    output wire    [7:0] fifo_output,
    output    full,
    output    empty
);

//spi_flash_read <-> qspi_ctrl
reg    sw;                    // Switch die signal

reg    [31:0] curr_addr;
reg    [31:0] curr_end_addr;
wire    [7:0] data2spi_read;    // Data read from SPI flash
wire    tx_flag;               // FIFO write done signal

qspi_controller qspi_ctrl4read (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .key(start_flag),
    .addr(curr_addr),
    .total_data_num(rom_data_num),
    .switch_die(sw),
    .mode(mode),
    .spi_clk(spi_clk),
    .cs_n(cs_n),
    .io0(sfr2qspi_io0),
    .io1(sfr2qspi_io1),
    .io2(sfr2qspi_io2),
    .io3(sfr2qspi_io3),
    .qspidata2spi_read(data2spi_read),
    .read_done(read_done),
    .tx_flag(tx_flag)
);

fifo_buffer #(
    .W(8),
    .D(256)
)  external_fifo (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .write_req(tx_flag),
    .fifo_dataIn(data2spi_read),
    .read_req(spi_read_req),
    .fifo_dataOut(fifo_output),
    .enable(1'b1),
    .empty(empty),
    .full(full)
);


always @ (posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n) 
            begin
                read_finish <= 1'b0;
                rom_data_num <= 16'd0;
                sw <= 1'b0;
                curr_addr <= start_addr;
                curr_end_addr <= end_addr;
            end
        else 
            begin
                if    (start_flag) 
                    begin
                        read_finish <= 1'b0;
                        sw <= 1'b0;
                        curr_addr <= start_addr;
                        curr_end_addr <= end_addr;
                        rom_data_num <= end_addr - start_addr + 1;
                    end
                if    (read_done)
                    begin
                        read_finish <= 1'b1;
                    end
                if    (curr_end_addr > 32'h01FFFFFF && switch_die_need) 
                    begin
                        if    (!read_finish) 
                            begin
                                rom_data_num <= 32'h01FFFFFF - curr_addr + 1;
                                sw <= 1'b0;
                            end
                        else 
                            begin
                                curr_addr <= 32'h00000000;
                                curr_end_addr <= curr_end_addr - 32'h01FFFFFF;
                                rom_data_num <= end_addr - 32'h01FFFFFF + 1;
                                sw <= 1'b1;
                            end
                    end
            end
    end
endmodule