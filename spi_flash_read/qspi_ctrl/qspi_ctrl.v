module qspi_controller (
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    key,
    input wire    [31:0] addr,
    input wire    [15:0] total_data_num,
    input wire    switch_die,
    input wire    [1:0] mode,

    output reg    spi_clk,
    output reg    cs_n,
    inout wire    io0, //mois
    inout wire    io1, //miso
    inout wire    io2,
    inout wire    io3,
    
    output wire   [7:0] qspidata2spi_read,
    output reg    read_done,
    output reg    po_flag
);

// State definitions
localparam    IDLE = 3'b000;
localparam    SWITCH_DIE = 3'b001;
localparam    READ = 3'b010;
localparam    COMPLETE = 3'b011;

// Instructions
localparam    STANDARD_READ = 8'h13;
localparam    DUAL_READ = 8'h3C;
localparam    QUAD_READ = 8'h6C;
localparam    SWITCH_DIE_INST = 8'hC2;
localparam    DIE_NUM = 8'h01;
localparam    DUMMY = 8'h00;

// Internal signals
reg    [2:0] state, next_state;
reg    [7:0] cmd;
reg    [15:0] byte_cnt;
reg    [2:0] bit_cnt;
reg    [4:0] system_clk_cnt;
reg    [1:0] spi_clk_cnt;
reg    [7:0] data_shift_reg; // 8-bit data shift register

reg    io0_flag;
reg    io1_flag;
reg    io2_flag;
reg    io3_flag;

wire    read_req;
wire    empty, full;
reg    po_flag_reg;
//reg    po_flag; // FIFO write request
reg    [7:0] po_data;

reg    mosi;
reg    miso;
reg    qspi_io2;
reg    qspi_io3;

reg    mosi_en;
reg    miso_en;
reg    qspi_io2_en;
reg    qspi_io3_en;
// IO assignment
assign io0 = mosi_en ? mosi : 1'bz;
assign io1 = miso_en ? miso : 1'bz;
assign io2 = qspi_io2_en ? qspi_io2 : 1'bz;
assign io3 = qspi_io3_en ? qspi_io3 : 1'bz;

//total num
wire    [15:0] dual_num;
wire    [15:0] quad_num;

assign dual_num = {1'b0,total_data_num[15:1]};
assign quad_num = {2'b00, total_data_num[15:2]};

assign read_req = (po_flag && !empty) ? 1'b1 : 1'b0;
// Clock generation

always @(posedge system_clk or negedge system_reset_n) 
    begin
        if    (!system_reset_n)
            begin
                system_clk_cnt <= 5'd0;
            end 
        else if    (state == SWITCH_DIE || state == READ)
            begin
                system_clk_cnt <= system_clk_cnt + 1'b1;
            end
    end

always @(posedge system_clk or negedge system_reset_n) 
    begin
        if    (!system_reset_n)
            begin
                byte_cnt <= 16'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == total_data_num + 16'd4) && (state == READ) && (mode == 2'b00))
            begin
                byte_cnt <= 16'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == dual_num + 16'd5) && (state == READ) && (mode == 2'b01))
            begin
                byte_cnt <= 16'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == quad_num + 16'd5) && (state == READ) && (mode == 2'b10))
            begin
                byte_cnt <= 16'd0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == 16'd2) && (state == SWITCH_DIE))
            begin
                byte_cnt <= 16'd0;
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
        else if    ((state == SWITCH_DIE) || (state == READ))
            begin
                spi_clk_cnt <= spi_clk_cnt + 1'b1;
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
        else if    ((byte_cnt == 16'd0) && (state == SWITCH_DIE))
            begin
                cs_n <= 1'b0;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == total_data_num + 16'd4) && (state == READ) && (mode == 2'b00))
            begin
                cs_n <= 1'b1;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == dual_num + 16'd5) && (state == READ) && (mode == 2'b01))
            begin
                cs_n <= 1'b1;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == quad_num + 16'd5) && (state == READ) && (mode == 2'b10))
            begin
                cs_n <= 1'b1;
            end
        else if    ((system_clk_cnt == 5'd31) && (byte_cnt == 16'd2) && (state == SWITCH_DIE))
            begin
                cs_n <= 1'b1;
            end
        else
            begin
                cs_n <= cs_n;
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

always @(*) begin
    case    (state)
        IDLE: 
            next_state = key ? (switch_die ? SWITCH_DIE : READ) : IDLE;
        SWITCH_DIE:
            next_state = (byte_cnt == 16'd2) ? READ : SWITCH_DIE;
        READ:
            if    (mode == 2'b00)
                next_state = ((byte_cnt == total_data_num + 16'd4) && (system_clk_cnt == 5'd31)) ? COMPLETE : READ;
            else if    (mode == 2'b01)
                next_state = ((byte_cnt == dual_num + 16'd5) && (system_clk_cnt == 5'd31)) ? COMPLETE : READ;
            else
                next_state = ((byte_cnt == quad_num + 16'd5) && (system_clk_cnt == 5'd31)) ? COMPLETE : READ;			
        COMPLETE:
            next_state = IDLE;
        default: 
            next_state = IDLE;
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
                read_done <= 1'b0;
            end
        else if    (state == IDLE)
		      begin
                mosi_en <= 1'b0;
                miso_en <= 1'b0;
                qspi_io2_en <= 1'b0;
                qspi_io3_en <= 1'b0;
                mosi <= 1'b0;
                miso <= 1'b0;
                qspi_io2 <= 1'b0;
                qspi_io3 <= 1'b0;
                read_done <= 1'b0;
				end
        else if    ((state == SWITCH_DIE) && (byte_cnt >=  16'd2))
            begin
                mosi_en <= 1'b0;
                mosi <= 1'b0;
            end
        else if    ((state == SWITCH_DIE) && (byte_cnt == 16'd0) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= SWITCH_DIE_INST[7 - bit_cnt];
            end
        else if    ((state == SWITCH_DIE) && (byte_cnt == 16'd1) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= DIE_NUM[7 - bit_cnt];
            end
        else if    ((state == SWITCH_DIE) && (byte_cnt == 16'd2) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b0;
            end
        else if    ((state == READ) && (byte_cnt == 16'd0) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= cmd[7 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt == 16'd1) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[31 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt == 16'd2) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[23 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt == 16'd3) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[15 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt == 16'd4) && (spi_clk_cnt == 2'd0))
            begin
                mosi_en <= 1'b1;
                mosi <= addr[7 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt == 16'd5) && (spi_clk_cnt == 2'd0) && (mode == 2'b01 || mode == 2'b10))
            begin
                mosi_en <= 1'b1;
                mosi <= DUMMY[7 - bit_cnt];
            end
        else if    ((state == READ) && (byte_cnt >= 16'd5) && (mode == 2'b00))
            begin
                mosi <= 1'b0;
                miso_en <= 1'b0;
            end
        else if    ((state == READ) && (byte_cnt >= 16'd6) && (mode == 2'b01))
            begin
                mosi_en <= 1'b0;
                miso_en <= 1'b0;
            end
        else if    ((state == READ) && (byte_cnt >= 16'd6) && (mode == 2'b10))
            begin
                mosi_en <= 1'b0;
                miso_en <= 1'b0;
                qspi_io2_en <= 1'b0;
                qspi_io3_en <= 1'b0;
            end
        else if    (state == COMPLETE)
            begin
                read_done <= 1'b1;
            end
    end

// Read instruction selection
always @(*) 
    begin
        case    (mode)
            2'b00: cmd = STANDARD_READ;
            2'b01: cmd = DUAL_READ;
            2'b10: cmd = QUAD_READ;
            default: cmd = STANDARD_READ;
        endcase
    end

//io0~io3 flag
always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                io0_flag <= 1'b0;
                io1_flag <= 1'b0;
                io2_flag <= 1'b0;
                io3_flag <= 1'b0;
            end
        else if    ((byte_cnt >= 16'd5) && (spi_clk_cnt == 2'd1) && (mode == 2'b00))
            begin
                io1_flag <= 1'b1;
            end
        else if    ((byte_cnt >= 16'd6) && (spi_clk_cnt == 2'd1) && (mode == 2'b01))
            begin
                io0_flag <= 1'b1;
                io1_flag <= 1'b1;
            end
        else if    ((byte_cnt >= 16'd6) && (spi_clk_cnt == 2'd1) && (mode == 2'b10))
            begin
                io0_flag <= 1'b1;
                io1_flag <= 1'b1;
                io2_flag <= 1'b1;
                io3_flag <= 1'b1;
            end
        else
            begin
                io0_flag <= 1'b0;
                io1_flag <= 1'b0;
                io2_flag <= 1'b0;
                io3_flag <= 1'b0;
            end
    end
// Data shift register
always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                data_shift_reg <= 8'd0;
            end
        else
            begin
                case    (mode)
                        2'b00:
                            begin
                                if    (io1_flag == 1'b1)
                                    begin
                                        data_shift_reg <= {data_shift_reg[6:0], io1};
                                    end
                            end
                        2'b01:
                            begin
                                if    ((io0_flag == 1'b1) && (io1_flag == 1'b1))
                                    begin
                                        data_shift_reg <= {data_shift_reg[5:0], io1, io0};
                                    end
                            end
                        2'b10:
                            begin
                                if    ((io0_flag == 1'b1) && (io1_flag == 1'b1) && (io2_flag == 1'b1) && (io3_flag == 1'b1))
                                    begin
                                        data_shift_reg <= {data_shift_reg[3:0], io3, io2, io1, io0};
                                    end
                            end
                endcase
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                po_flag_reg <= 1'b0;
            end
        else
            begin
                case    (mode)
                        2'b00:
                            begin
                                if    ((bit_cnt == 3'd7) && (miso_en == 1'b0) && (io1_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else
                                    begin
                                        po_flag_reg <= 1'b0;
                                    end
                            end
                        2'b01:
                            begin
                                if    ((bit_cnt == 3'd3) && (miso_en == 1'b0) && (mosi_en == 1'b0) && (io0_flag == 1'b1) && (io1_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else if    ((bit_cnt == 3'd7) && (miso_en == 1'b0) && (mosi_en == 1'b0) && (io0_flag == 1'b1) && (io1_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else
                                    begin
                                        po_flag_reg <= 1'b0;
                                    end
                            end
                        2'b10:
                            begin
                                if    ((bit_cnt == 3'd1) && (miso_en == 1'b0) && (mosi_en == 1'b0) && (qspi_io2_en == 1'b0) && (qspi_io3_en == 1'b0) && (io0_flag == 1'b1) && (io1_flag == 1'b1) && (io2_flag == 1'b1) && (io3_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else if    ((bit_cnt == 3'd3) && (miso_en == 1'b0) && (mosi_en == 1'b0) && (qspi_io2_en == 1'b0) && (qspi_io3_en == 1'b0) && (io0_flag == 1'b1) && (io1_flag == 1'b1) && (io2_flag == 1'b1) && (io3_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else if    ((bit_cnt == 3'd7) && (miso_en == 1'b0) && (mosi_en == 1'b0) && (qspi_io2_en == 1'b0) && (qspi_io3_en == 1'b0) && (io0_flag == 1'b1) && (io1_flag == 1'b1) && (io2_flag == 1'b1) && (io3_flag == 1'b1))
                                    begin
                                        po_flag_reg <= 1'b1;
                                    end
                                else
                                    begin
                                        po_flag_reg <= 1'b0;
                                    end
                            end
                endcase
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                po_flag <= 1'b0;
            end
        else
            begin
                po_flag <= po_flag_reg;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                po_data <= 8'd0;
            end
        else if    (po_flag_reg == 1'b1)
            begin
                po_data <= data_shift_reg;
            end
        else
            begin
                po_data <= po_data;
            end
    end


fifo_buffer #(
    .W(8),
    .D(256)
) internal_fifo (
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .read_req(read_req),
    .write_req(po_flag),
    .fifo_dataIn(po_data),
    .fifo_dataOut(qspidata2spi_read),
    .empty(empty),
    .full(full)
);

endmodule