module flash_se_ctrl (
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    key,
    input wire    [31:0] addr,
    output reg    cs_n,
    output reg    spi_clk,
    inout wire    io0,
    output reg    se_done
);

localparam    IDLE = 4'b0000;
localparam    WR_EN = 4'b0001;
localparam    DELAY = 4'b0010;
localparam    SE = 4'b0011;
localparam    SEDONE = 4'b0100;

localparam    WR_EN_INST = 8'h06;
localparam    SE_INST = 8'h21;

// Internal signals
reg    [2:0] state, next_state;
reg    [3:0] byte_cnt;
reg    [2:0] bit_cnt;
reg    [4:0] system_clk_cnt;
reg    [1:0] spi_clk_cnt;

reg    io0_flag;
reg    mosi;

reg    mosi_en;

assign io0 = mosi_en? mosi : 1'bz;
//state machine
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
                spi_clk_cnt <= 2'd0;
            end
        else if    ((state == WR_EN) && (byte_cnt == 4'd1))
            begin
                spi_clk_cnt <= spi_clk_cnt + 1'b1;
            end
        else if    ((state == SE) && (byte_cnt >= 4'd5) && (byte_cnt < 4'd10))
            begin
                spi_clk_cnt <= spi_clk_cnt + 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                byte_cnt <= 4'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == 4'd10)) 
            begin
                byte_cnt <= 4'd0;
            end
        else if    (system_clk_cnt == 5'd31)
            begin
                byte_cnt <= byte_cnt + 1'b1;
            end
    end

//cs_n
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
        else if    ((state == WR_EN) && (byte_cnt == 4'd2) && (system_clk_cnt == 5'd31))
            begin
                cs_n <= 1'b1;
            end
        else if    ((state == DELAY) && (byte_cnt == 4'd3) && (system_clk_cnt == 5'd31))
            begin
                cs_n <= 1'b0;
            end
        else if    ((state == SE) && (byte_cnt == 4'd10) && (system_clk_cnt == 5'd31))
            begin
                cs_n <= 1'b1;
            end
    end

//spi_clk
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
                    if    ((byte_cnt == 4'd2) && (system_clk_cnt == 5'd31))
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
                    if    ((byte_cnt == 4'd3) && (system_clk_cnt == 5'd31))
                        begin
                            next_state = SE;
                        end
                    else
                        begin
                            next_state = DELAY;
                        end
                end
            SE:
                begin
                    if    ((byte_cnt == 4'd10) && (system_clk_cnt == 5'd31))
                        begin
                            next_state = SEDONE;
                        end
                    else
                        begin
                            next_state = SE;
                        end
                end
            SEDONE:
                begin
                    next_state = (se_done && cs_n) ? IDLE : SEDONE;
                end
            default:
                next_state = IDLE;
        endcase
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                mosi_en <= 1'b0;
                mosi <= 1'b0;
                se_done <= 1'b0;
            end
        else if    (state == IDLE)
            begin
                mosi_en <= 1'b0;
                mosi <= 1'b0;
                se_done <= 1'b0;
            end
        else if    ((state == WR_EN) && (byte_cnt == 4'd0))
            begin
                mosi_en <= 1'b1;
            end
        else if    ((state == WR_EN) && (byte_cnt == 4'd1) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= WR_EN_INST[7 - bit_cnt];
            end
        else if    ((state == WR_EN) && (byte_cnt == 4'd2))
            begin
                mosi_en <= 1'b1;                
                mosi <= 1'b0;
            end

        else if    ((state == SE) && (byte_cnt == 4'd5) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= SE_INST[7 - bit_cnt];
            end
        else if    ((state == SE) && (byte_cnt == 4'd6) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[31 - bit_cnt];
            end
        else if    ((state == SE) && (byte_cnt == 4'd7) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[23 - bit_cnt];
            end
        else if    ((state == SE) && (byte_cnt == 4'd8) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[15 - bit_cnt];
            end
        else if    ((state == SE) && (byte_cnt == 4'd9) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[7 - bit_cnt];
            end
        else if    ((state == SE) && (byte_cnt == 4'd10))
            begin
                mosi_en <= 1'b1;
                mosi <= 1'b0;
            end
        else if    (state == SEDONE)
            begin
                se_done <= 1'b1;
            end
    end
endmodule