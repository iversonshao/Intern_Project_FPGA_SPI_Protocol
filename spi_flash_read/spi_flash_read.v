module spi_flash_read(
    input wire    system_clk,       // System clock input
    input wire    system_reset_n,          // Active low reset input
    input wire    start_flag,            // Start signal input
    input wire    [31:0] start_addr, // Start address input (32 bits for flexibility)
    input wire    [31:0] end_addr,   // End address input (32 bits for flexibility)
    input wire    [1:0] mode,            // Mode input (0: Single, 1: Dual, 2: Quad)
    input wire    read_req,       // Read request signal input
    input wire    switch_die_need,
    inout wire    sfr2qspi_io0,    // SPI flash read data I/O 0
    inout wire    sfr2qspi_io1,    // SPI flash read data I/O 1
    inout wire    sfr2qspi_io2,    // SPI flash read data I/O 2
    inout wire    sfr2qspi_io3,    // SPI flash read data I/O 3
    output reg    read_finish          // Read finish signal output     
);

localparam IDLE = 3'd0, 
           CHECK_MODE = 3'd1,
           CHECK_SWITCH = 3'd2,
           READ_DATA = 3'd3,
           DONE = 3'd4;

//state
reg    [2:0] state, next_state; // State and next state registers
reg    [31:0] curr_addr;     // Current address register (32 bits)
reg    [31:0] end_point;     // End point register (32 bits)
//spi_flash_read <-> qspi_ctrl
wire    qspi2spi_flash_read_done;    // SPI flash read done signal
reg    sw;                    // Switch die signal
wire    read_flag;            // Start read signal
reg    [1:0] mode2qspi_ctrl;        // Mode signal
//qspi_ctrl <-> fifo_buffer
wire    write_req2fifo;              // Write request signal
wire    [7:0] qspictrl_data2fifo;     // FIFO data input (8 bits)

wire    [7:0] fifo_output;    // FIFO data output (8 bits)
wire    empty, full;          // FIFO empty and full signals

reg read_done_once;

qspi_controller qspi_ctrl4read (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .read_flag(read_flag),
    .read_addr(curr_addr),
    .switch_die(sw),
    .mode(mode2qspi_ctrl),
    .spi_clk(spi_clk),
    .cs_n(cs_n),
    .io0(sfr2qspi_io0),
    .io1(sfr2qspi_io1),
    .io2(sfr2qspi_io2),
    .io3(sfr2qspi_io3),
    .data_qspi2fifo(qspictrl_data2fifo),
    .write_req(write_req2fifo),
    .read_done(qspi2spi_flash_read_done)
);

fifo_buffer f1 (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .read_req(read_req),
    .write_req(write_req2fifo),
    .fifo_dataIn(qspictrl_data2fifo),
    .fifo_dataOut(fifo_output),
    .empty(empty),
    .full(full)
);

assign read_flag = start_flag && (state == READ_DATA);

always @(posedge system_clk or negedge system_reset_n)
    begin
        if (!system_reset_n)
            begin
                state <= IDLE;
            end
        else
            begin
                state <= next_state;
            end
    end

always @(*)
    begin
        case (state)
            IDLE:
                begin
                    next_state = start_flag ? CHECK_MODE : IDLE;
                end
            CHECK_MODE:
                begin
                    next_state = switch_die_need ? CHECK_SWITCH : READ_DATA;
                end
            CHECK_SWITCH:
                begin
                    if    (curr_addr > 32'h01FFFFFF && switch_die_need)
                        begin
                            next_state = CHECK_SWITCH;
                        end
                    else
                        begin
                            next_state = READ_DATA;
                        end
                end
            READ_DATA:
                begin
                    if    (curr_addr == end_point + 32'h00000001)
                        begin
                            next_state = DONE;
                        end
                    else if    (curr_addr > 32'h01FFFFFF && switch_die_need)
                        begin
                            next_state = CHECK_SWITCH;
                        end
                    else if    (!full)
                        begin
                            next_state = READ_DATA;
                        end
                    else
                        begin
                            next_state = READ_DATA;
                        end
                end
            DONE:
                begin
                    next_state = IDLE;
                end
            default:
                begin
                    next_state = IDLE;
                end
        endcase
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if (!system_reset_n)
            begin
                read_finish <= 1'b0;
                curr_addr <= 32'd0;
                end_point <= 32'd0;
                sw <= 1'b0;
                mode2qspi_ctrl <= 2'b00;
                read_done_once <= 1'b0;
            end
        else
            begin
                case (state)
                    IDLE:
                        begin
                            read_finish <= 1'b0;
                            curr_addr <= start_addr;
                            end_point <= end_addr;
                            sw <= 1'b0;
                            read_done_once <= 1'b0;
                        end
                    CHECK_MODE:
                        begin
                            mode2qspi_ctrl <= mode;
                        end
                    CHECK_SWITCH:
                        begin
                            if   (curr_addr > 32'h01FFFFFF && switch_die_need)
                                begin
                                    curr_addr <= 32'h00000000;
                                    end_point <= end_point - 32'h01FFFFFF;
                                    sw <= 1'b1;
                                end
                            else
                                begin
                                    sw <= 1'b0;
                                end
                        end
                    READ_DATA:
                        begin
                            if    (qspi2spi_flash_read_done)
                                begin
                                    read_done_once <= 1'b1;
                                end
                            else
                                begin
                                    if    (read_done_once)
                                        begin
                                            curr_addr <= curr_addr + 32'h00000001;
                                            read_done_once <= 1'b0;
                                        end
                                end
                        end
                    DONE:
                        begin
                            read_finish <= 1'b1;
                            read_done_once <= 1'b0;
                            curr_addr <= 32'h00000000;
                        end
                    default:
                        begin
                            read_finish <= 1'b0;
                            curr_addr <= 32'h00000000;
                            sw <= 1'b0;
                            mode2qspi_ctrl <= 2'b00;
                            read_done_once <= 1'b0;
                        end
                endcase
            end
    end
endmodule