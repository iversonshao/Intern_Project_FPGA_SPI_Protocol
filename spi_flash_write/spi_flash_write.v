`define TSE    60    //sector erase cycle time (60ns)
module spi_flash_write(
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    pi_flag,
    input wire    [31:0] write_start_addr,
    input wire    [7:0] write_data,
    input wire    [15:0] write_num,
    output wire    se_done,
    output wire    pp_done,
    output reg    cs_n,
    output reg    spi_clk,
    inout wire    io0,
    inout wire    io1,
    inout wire    io2,
    inout wire    io3,
    input wire    mode,
    output reg    write_finish
);

reg    [31:0] se_addr;
reg    [31:0] pp_addr;
reg    [8:0] pp_num;
reg    [15:0] pp_num_reg;
// reg    [3:0] se_count;
reg    [3:0] pp_count;
reg    se_key, pp_key;
reg    [5:0] tse_count;

reg    [2:0] state, next_state;

wire    se_cs_n, pp_cs_n, se_spi_clk, pp_spi_clk;

localparam    IDLE = 3'b000;
localparam    SE = 3'b001;
localparam    SE_WAIT = 3'b010;
localparam    PP = 3'b011;
localparam    PP_WAIT = 3'b100;
localparam    FINISH = 3'b101;

reg    mosi;
reg    miso;
reg    qspi_io2;
reg    qspi_io3;

reg    mosi_en;
reg    miso_en;
reg    qspi_io2_en;
reg    qspi_io3_en;

assign io0 = mosi_en ? mosi : 1'bz;
assign io1 = miso_en ? miso : 1'bz;
assign io2 = qspi_io2_en ? qspi_io2 : 1'bz;
assign io3 = qspi_io3_en ? qspi_io3 : 1'bz;

// State machine
always @(posedge system_clk or negedge system_reset_n) 
    begin
        if    (!system_reset_n)
            begin
                state <= IDLE;
            end
        else
            begin
                state <= next_state;
            end
    end

// always @(*)
//     begin
//         if    (!system_reset_n)
//             begin
//                 se_count <= 4'd0;
//             end
//         else if    (write_num <= 16'd4096)
//             begin
//                 se_count <= 4'd1;
//             end
//         else
//             begin
//                 se_count <= {1'b0, write_num[15:13]} + 4'd1;
//             end
//     end
            
//4KB sector
flash_se_ctrl se(
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .key(se_key),
    .addr(se_addr),
    .cs_n(se_cs_n),
    .spi_clk(se_spi_clk),
    .io0(se_io0),
    .se_done(se_done)
);

flash_pp_ctrl pp(
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .key(pp_key),
    .pp_num(pp_num),
    .addr(pp_addr),
    .data(write_data),
    .cs_n(pp_cs_n),
    .spi_clk(pp_spi_clk),
    .io0(pp_io0),
    .io1(pp_io1),
    .io2(pp_io2),
    .io3(pp_io3),
    .mode(mode),
    .pp_done(pp_done)
);

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                mosi_en <= 1'b1;
                mosi <= 1'b0;
            end
        else
            begin
                if    (state == IDLE)
                    begin
                        mosi_en <= 1'b1;
                        mosi <= 1'b0;
                    end
                else if    (state == SE)
                    begin
                        mosi_en <= 1'b1;
                        mosi <= se_io0;
                    end
                else if    (state == SE_WAIT)
                    begin
                        mosi_en <= 1'b1;
                        mosi <= 1'b0;
                    end
                else if    (state == PP)
                    begin
                        if    (mode == 1'b0)
                            begin
                                mosi_en <= 1'b1;
                                mosi <= pp_io0;
                            end
                        else if    (mode == 1'b1)
                            begin
                                mosi_en <= 1'b1;
                                mosi <= pp_io0;
                                miso_en <= 1'b1;
                                miso <= pp_io1;
                                qspi_io2_en <= 1'b1;
                                qspi_io2 <= pp_io2;
                                qspi_io3_en <= 1'b1;
                                qspi_io3 <= pp_io3;
                            end
                    end
                else if    (state == PP_WAIT)
                    begin
                        mosi_en <= 1'b1;
                        mosi <= 1'b0;
                    end
                else
                    begin
                        mosi_en <= 1'b0;
                    end
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                spi_clk <= 1'b0;
                cs_n <= 1'b1;
            end
        else
            begin
                if    (state == IDLE)
                    begin
                        spi_clk <= 1'b0;
                        cs_n <= 1'b1;
                    end
                else if    (state == SE)
                    begin
                        spi_clk <= se_spi_clk;
                        cs_n <= se_cs_n;
                    end
                else if    (state == SE_WAIT)
                    begin
                        spi_clk <= 1'b0;
                        cs_n <= 1'b1;
                    end
                else if    (state == PP)
                    begin
                        spi_clk <= pp_spi_clk;
                        cs_n <= pp_cs_n;
                    end
                else if    (state == PP_WAIT)
                    begin
                        spi_clk <= 1'b0;
                        cs_n <= 1'b1;
                    end
                else
                    begin
                        spi_clk <= 1'b0;
                        cs_n <= 1'b1;
                    end
            end
    end

always @(*)
    begin
        case    (state)
            IDLE:
                begin
                    next_state = (pi_flag) ? SE : IDLE;
                end
            SE:
                begin
                    next_state = se_done ? SE_WAIT : SE;
                end
            SE_WAIT:
                begin
                    next_state = (tse_count == `TSE - 1) ? PP : SE_WAIT;
                end
            PP:
                begin
                    next_state = pp_done ? PP_WAIT : PP;
                end
            PP_WAIT:
                begin
                    if    (pp_num_reg >= write_num - 16'd256)
                        begin
                            next_state = FINISH;
                        end
                    else if    (pp_count == 4'd15)
                        begin
                            next_state = SE;
                        end
                    else
                        begin
                            next_state = PP;
                        end
                end
            FINISH:
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
        if    (!system_reset_n)
            begin
                se_addr <= 32'd0;
                pp_addr <= 32'd0;
                pp_num <= 9'd0;
                pp_num_reg <= 16'd0;
                se_key <= 1'b0;
                pp_key <= 1'b0;
                tse_count <= 6'd0;
                pp_count <= 4'd0;
                write_finish <= 1'b0;
            end
        else
            begin
                case    (state)
                    IDLE:
                        begin
                            pp_num <= 9'd0;
                            tse_count <= 6'd0;
                            pp_num_reg <= 16'd0;
                            pp_count <= 4'd0;
                            pp_key <= 1'b0;
                            write_finish <= 1'b0;
                            if    (pi_flag)
                                begin
                                    se_addr <= write_start_addr;
                                    pp_addr <= write_start_addr;
                                    se_key <= 1'b1;
                                end
                        end
                    SE:
                        begin
                            if    (se_key)
                                begin
                                    se_key <= 1'b0;
                                    tse_count <= 6'd0;
                                end
                            else if    (se_done)
                                begin
                                    se_addr <= se_addr + 32'd4096;
                                end
                            else
                                begin
                                    se_key <= 1'b0;
                                end
                        end
                    SE_WAIT:
                        begin
                            if    (se_done)
                                se_key <= 1'b0;
                                tse_count <= tse_count + 6'd1; 
                                if    (tse_count == `TSE - 2)
                                    begin
                                        pp_key <= 1'b1;
                                    end
                        end
                    PP:
                        begin
                            if   (pp_key)
                                begin
                                    pp_key <= 1'b0;
                                end
                            pp_num <= ((write_num - pp_num_reg) >= 16'd256) ? 9'd256 : write_num - pp_num_reg;
                        end
                    PP_WAIT:
                        begin
                            if    (pp_done)
                                begin
                                    pp_addr <= pp_addr + 32'd256;
                                    pp_num_reg <= pp_num_reg + pp_num;
                                    pp_count <= pp_count + 1'b1;
                                    pp_key <= 1'b1;
                                    if    (pp_count == 4'd15)
                                        begin
                                            se_key <= 1'b1;
                                        end
                                    else if    (pp_num_reg >= write_num - 16'd256)
                                        begin
                                            pp_key <= 1'b0;
                                        end
                                end
                        end
                    FINISH:
                        begin
                            write_finish <= 1'b1;
                        end
                endcase
            end
    end
endmodule