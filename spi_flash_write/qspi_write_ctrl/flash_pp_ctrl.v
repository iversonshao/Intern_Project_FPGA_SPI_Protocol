module flash_pp_ctrl (
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    key,
    input wire    [8:0] pp_num,
    input wire    [31:0] addr,
    input wire    [7:0] data,
    input wire    mode, // 0: PP, 1: PPX4
    output reg    cs_n,
    output reg    spi_clk,
    inout wire    io0,
    inout wire    io1,
    inout wire    io2,
    inout wire    io3,
    output reg    pp_done
);

localparam    IDLE = 4'b0000;
localparam    WR_EN = 4'b0001;
localparam    DELAY = 4'b0010;
localparam    PP = 4'b0011;
localparam    PPDONE = 4'b0100;

localparam    WR_EN_INST = 8'h06;
localparam    PP_INST = 8'h12;
localparam    PPX4_INST = 8'h3E;

reg    [2:0] state, next_state;
reg    [8:0] byte_cnt;
reg    [2:0] bit_cnt;
reg    [4:0] system_clk_cnt;
reg    [1:0] spi_clk_cnt;
reg    [7:0] data_num;

// reg    io0_flag;

reg    mosi;
reg    miso;
reg    qspi_io2;
reg    qspi_io3;


reg    mosi_en;
reg    miso_en;
reg    qspi_io2_en;
reg    qspi_io3_en;

wire    pp4x_num;

assign io0 = mosi_en? mosi : 1'bz;
assign io1 = miso_en? miso : 1'bz;
assign io2 = qspi_io2_en? qspi_io2 : 1'bz;
assign io3 = qspi_io3_en? qspi_io3 : 1'bz;

assign pp4x_num = (mode == 1) ? pp_num >> 2 : 1'bz;

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

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                system_clk_cnt <= 5'd0;
            end
        else if    (state != IDLE)
            begin
                system_clk_cnt <= system_clk_cnt + 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                byte_cnt <= 9'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == pp_num + 9'd10) && (mode == 0))
            begin
                byte_cnt <= 9'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == pp4x_num + 9'd7) && (mode == 1))
            begin
                byte_cnt <= 9'd0;
            end
        else if    (system_clk_cnt == 5'd31)
            begin
                byte_cnt <= byte_cnt + 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                spi_clk_cnt <= 2'd0;
            end
        else if    ((state == WR_EN) && (byte_cnt == 9'd1))
            begin
                spi_clk_cnt <= spi_clk_cnt + 1'b1;
            end
        else if    (state == PP)
            begin
                if    ((mode == 0) && (byte_cnt >= 9'd5) && (byte_cnt < pp_num + 9'd11 - 1'b1))
                    begin
                        spi_clk_cnt <= spi_clk_cnt + 1'b1;
                    end
                else if    ((mode == 1) && (byte_cnt >= 9'd5) && (byte_cnt < pp4x_num + 9'd8 - 1'b1))
                    begin
                        spi_clk_cnt <= spi_clk_cnt + 1'b1;
                    end
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                cs_n <= 1'b1;
            end
        else if    (key == 1'b1)
            begin
                cs_n <= 1'b0;
            end
        else if    ((state == WR_EN) && (byte_cnt == 9'd2) && (system_clk_cnt == 5'd31))
            begin
                cs_n <= 1'b1;
            end
        else if    ((state == DELAY) && (byte_cnt == 9'd3) && (system_clk_cnt == 5'd31))
            begin
                cs_n <= 1'b0;
            end
        else if    ((state == PP) && (byte_cnt == pp_num + 9'd10) && (system_clk_cnt == 5'd31) && (mode == 0))
            begin
                cs_n <= 1'b1;
            end
        else if    ((state == PP) && (byte_cnt == pp4x_num + 9'd7) && (system_clk_cnt == 5'd31) && (mode == 1))
            begin
                cs_n <= 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                spi_clk <= 1'b0;
            end
        else if    (spi_clk_cnt == 2'd0)
            begin
                spi_clk <= 1'b0;
            end
        else if    (spi_clk_cnt == 2'd2)
            begin
                spi_clk <= 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                bit_cnt <= 3'd0;
            end
        else if    (spi_clk_cnt == 2'd2)
            begin
                bit_cnt <= bit_cnt + 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                data_num <= 8'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt >= 9'd10) && (byte_cnt < pp_num + 9'd11 - 1'b1) && (mode == 0))
            begin
                data_num <= data_num + 1'b1;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt >= 9'd7) && (byte_cnt < pp4x_num + 9'd8 - 1'b1) && (mode == 1))
            begin
                data_num <= data_num + 1'b1;
            end
    end

always @(*)
    begin
        case    (state)
            IDLE:
                begin
                    if    (key == 1'b1)
                        begin
                            next_state = WR_EN;
                        end
                    else
                        begin
                            next_state = IDLE;
                        end
                end
            WR_EN:
                begin
                    if    ((byte_cnt == 8'd2) && (system_clk_cnt == 5'd31))
                        begin
                            next_state = DELAY;
                        end
                    else
                        begin
                            next_state = WR_EN;
                        end
                end
            DELAY:
                begin
                    if    ((byte_cnt == 8'd3) && (system_clk_cnt == 5'd31))
                        begin
                            next_state = PP;
                        end
                    else
                        begin
                            next_state = DELAY;
                        end
                end
            PP:
                begin
                    if    ((byte_cnt == pp_num + 9'd10) && (system_clk_cnt == 5'd31) && (mode == 0))
                        begin
                            next_state = PPDONE;
                        end
                    else if    ((byte_cnt == pp4x_num + 9'd7) && (system_clk_cnt == 5'd31) && (mode == 1))
                        begin
                            next_state = PPDONE;
                        end
                    else
                        begin
                            next_state = PP;
                        end
                end
            PPDONE:
                begin
                    next_state = (cs_n && pp_done) ? IDLE : PPDONE;
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
                mosi_en <= 1'b0;
                miso_en <= 1'b0;
                qspi_io2_en <= 1'b0;
                qspi_io3_en <= 1'b0;
                mosi <= 1'b0;
                miso <= 1'b0;
                qspi_io2 <= 1'b0;
                qspi_io3 <= 1'b0;
                pp_done <= 1'b0;
            end
        else if    (state == IDLE)
            begin
                mosi_en <= 1'b0;
                miso_en <= 1'b0;
                qspi_io2_en <= 1'b0;
                qspi_io3_en <= 1'b0;
                pp_done <= 1'b0;
            end
        else if    ((state == WR_EN) && (byte_cnt == 9'd0))
            begin
                mosi_en <= 1'b1;
                
            end  
        else if    ((state == WR_EN) && (byte_cnt == 9'd1) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= WR_EN_INST[7 - bit_cnt];
            end      
        else if    ((state == WR_EN) && (byte_cnt == 9'd2))
            begin
                mosi_en <= 1'b0;
                mosi <= 1'b0;
                pp_done <= 1'b0;
            end
        else if    (state == PP)
            begin
                if    (mode == 0)
                    begin
                        if    ((byte_cnt == 9'd5) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= PP_INST[7 - bit_cnt];
                            end
                        else if    ((byte_cnt == 9'd6) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= addr[31 - bit_cnt];
                            end
                        else if    ((byte_cnt == 9'd7) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= addr[23 - bit_cnt];
                            end
                        else if    ((byte_cnt == 9'd8) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= addr[15 - bit_cnt];
                            end
                        else if    ((byte_cnt == 9'd9) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= addr[7 - bit_cnt];
                            end
                        else if    ((byte_cnt >= 9'd10) && (byte_cnt < (pp_num + 9'd11 - 1'b1)) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= data[7 - bit_cnt];
                            end
                        else if    ((byte_cnt == pp_num + 9'd10))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= 1'b0;
                                pp_done <= 1'b0;
                            end
                    end
                else if    (mode == 1)
                    begin
                        if    ((byte_cnt == 9'd5) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                mosi <= PPX4_INST[7 - bit_cnt];
                            end
                        else if    ((byte_cnt == 9'd6) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                miso_en <= 1'b1;
                                qspi_io2_en <= 1'b1;
                                qspi_io3_en <= 1'b1;
                                mosi <= addr[28 - bit_cnt*4];
                                miso <= addr[29 - bit_cnt*4];
                                qspi_io2 <= addr[30 - bit_cnt*4];
                                qspi_io3 <= addr[31 - bit_cnt*4];

                            end
                        else if    ((byte_cnt >= 9'd7) && (byte_cnt < (pp4x_num + 9'd8 - 1'b1)) && (spi_clk_cnt == 2'd0))
                            begin
                                mosi_en <= 1'b1;
                                miso_en <= 1'b1;
                                qspi_io2_en <= 1'b1;
                                qspi_io3_en <= 1'b1;
                                if    ((bit_cnt == 0) || (bit_cnt ==2) || (bit_cnt == 4) || (bit_cnt == 6))
                                    begin
                                        mosi <= data[4];
                                        miso <= data[5];
                                        qspi_io2 <= data[6];
                                        qspi_io3 <= data[7];
                                    end
                                else if    ((bit_cnt == 1) || (bit_cnt == 3) || (bit_cnt == 5) || (bit_cnt == 7))
                                    begin
                                        mosi <= data[0];
                                        miso <= data[1];
                                        qspi_io2 <= data[2];
                                        qspi_io3 <= data[3];
                                    end
                            end
                        else if    ((state == PP) && (byte_cnt == pp4x_num + 9'd7))
                            begin
                                mosi_en <= 1'b1;
                                miso_en <= 1'b1;
                                qspi_io2_en <= 1'b1;
                                qspi_io3_en <= 1'b1;
                                mosi <= 1'b0;
                                miso <= 1'b0;
                                qspi_io2 <= 1'b0;
                                qspi_io3 <= 1'b0;
                                pp_done <= 1'b0;
                            end
                    end
            end

        else if    (state == PPDONE)
            begin
                pp_done <= 1'b1;
            end
    end
endmodule