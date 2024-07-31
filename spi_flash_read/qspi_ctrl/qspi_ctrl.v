module qspi_controller (
    input wire    system_clk,       // System clock input up to 50 MHz
    input wire    system_reset_n,          // Active low reset input
    input wire    read_flag,            // read signal input
    input wire    [31:0] read_addr,
    input wire    switch_die,            // switch die signal input
    input wire    [1:0] mode,            // mode signal input

    output    spi_clk,          // SPI clock output         
    output reg    cs_n,             // SPI chip select (active low)             
    inout    io0,//d0 mosi
    inout    io1,//d1 miso
    inout    io2,
    inout    io3,
    //FIFO
    output reg    [7:0] data_qspi2fifo,
    output reg    write_req,        // write request signal
    // output reg    ready,            // ready signal        
    output reg    read_done         // Read done signal         
);

    // State definitions for the state machine
    localparam IDLE = 3'd0, 
               SWITCH_DIE = 3'd1,
               READ = 3'd2, 
               SEND = 3'd3,
               COMPLETE = 3'd4;

    // Internal signals
    reg    [2:0] state, next_state; // State and next state registers
    reg    [31:0] addr;             // Address register (32 bits)
    reg    [7:0] shift_reg;         // Shift register for data read
    reg    data_written;     // Data written register

    reg    [5:0] switch_die_count; // Switch die count register
    reg    [6:0] read_count;         // read count register
    reg    [6:0] d_read_count;         // read count register
    reg    [6:0] q_read_count;         // read count register
    reg    [4:0] send_count;       // send count register

    // QSPI signals
    reg    mosi;//io0 dI MOSI signal
    reg    miso;//io1 dO MISO signal
    reg    qspi_io2;
    reg    qspi_io3;

    reg    mosi_out_en;
    reg    miso_out_en;
    reg    qspi_io2_out_en;
    reg    qspi_io3_out_en;

    // clock divider
    assign spi_clk = system_reset_n ? system_clk : 0;
    
    //IO way ctrl
    assign io0 = mosi_out_en ? mosi : 1'bZ;
    assign io1 = miso_out_en ? miso : 1'bZ;
    assign io2 = qspi_io2_out_en ? qspi_io2 : 1'bZ;
    assign io3 = qspi_io3_out_en ? qspi_io3 : 1'bZ;
    // Instruction
    localparam SWITCH_CMD = 8'hC2;
    localparam READ_CMD = 8'h13;
    localparam DUAL_READ = 8'h3C;
    localparam QUAD_READ = 8'h6C;
    localparam SWITCH_DIE_NUM = 8'h01;

    // State register update
    always @(negedge system_clk or negedge system_reset_n) 
        begin
            if    (!system_reset_n)
                begin
                    state <= IDLE;
                end
            else
                begin
                    state <= next_state; // Update state with the next state
                end
        end
    // State transition logic
    always @(*) 
        begin
            case    (state)
                IDLE: 
                    begin
                        if    (read_flag)
                            begin
                                next_state = switch_die ? SWITCH_DIE : READ;
                            end
                        else
                            begin
                                next_state = IDLE;
                            end
                    end
                SWITCH_DIE:
                    begin
                        next_state = (switch_die_count == 6'd15) ? READ : SWITCH_DIE;
                    end
                READ:
                    begin
                        case    (mode)
                                2'b00: 
                                    begin
                                        next_state = (read_count == 7'd38) ? SEND : READ;
                                    end
                                2'b01: 
                                    begin
                                        next_state = (d_read_count == 7'd38) ? SEND : READ;
                                    end
                                2'b10: 
                                    begin
                                        next_state = (q_read_count == 7'd38) ? SEND : READ;
                                    end
                            default:
                                begin
                                    next_state = (read_count == 7'd38) ? SEND : READ;
                                end
                        endcase
                    end
                SEND:
                    begin
                        next_state = data_written ? COMPLETE : SEND;
                    end
                COMPLETE:
                    begin
                        next_state = read_done ? IDLE : COMPLETE;
                    end
                default:
                    begin
                        next_state = IDLE;
                    end
            endcase
        end

    // State output logic
    always @(negedge system_clk or negedge system_reset_n) 
        begin
            if    (!system_reset_n) 
                begin
                // Reset values for all registers
                    cs_n <= 1'b1;
                    addr <= 32'd0;
                    read_done <= 1'b0;
                    shift_reg <= 8'd0;
                    write_req <= 1'b0;
                    // ready <= 1'b1;
                    data_written <= 1'b0;
                    switch_die_count <= 6'd0;
                    read_count <= 7'd0;
                    d_read_count <= 7'd0;
                    q_read_count <= 7'd0;
                    send_count <= 5'd0;
                    mosi_out_en <= 1'b0;
                    miso_out_en <= 1'b0;
                    qspi_io2_out_en <= 1'b0;
                    qspi_io3_out_en <= 1'b0;
                    data_qspi2fifo <= 8'd0;
                    mosi <= 1'b0;
                    miso <= 1'b0;
                    qspi_io2 <= 1'b0;
                    qspi_io3 <= 1'b0;
                end 
            else 
                begin
                    case    (state)
                        IDLE:
                            begin
                            // Initialize values for starting a new transaction
                                cs_n <= 1'b1;
                                addr <= read_addr;
                                read_done <= 1'b0;
                                shift_reg <= 8'd0;
                                write_req <= 1'b0;
                                // ready <= 1'b1;
                                data_written <= 1'b0;
                                switch_die_count <= 6'd0;
                                read_count <= 7'd0;
                                d_read_count <= 7'd0;
                                q_read_count <= 7'd0;
                                send_count <= 5'd0;
                                mosi_out_en <= 1'b0;
                                miso_out_en <= 1'b0;
                                qspi_io2_out_en <= 1'b0;
                                qspi_io3_out_en <= 1'b0;
                                data_qspi2fifo <= 8'd0;
                                mosi <= 1'b0;
                                miso <= 1'b0;
                                qspi_io2 <= 1'b0;
                                qspi_io3 <= 1'b0;
                            end   
                        SWITCH_DIE:
                            begin
                            // Send C2h command to switch die
                                // ready <= 1'b0;
                                mosi_out_en <= 1'b1;
                                if    (cs_n == 1'b1)
                                    begin
                                        cs_n <= 1'b0;
                                        mosi <= SWITCH_CMD[7];
                                        switch_die_count <= 6'd0;
                                    end
                                else
                                    begin
                                        if    (switch_die_count < 6'd15)
                                            begin
                                                mosi <= (switch_die_count < 6'd7) ? SWITCH_CMD[6 - switch_die_count] : SWITCH_DIE_NUM[14 - switch_die_count];
                                                switch_die_count <= switch_die_count + 6'd1;
                                            end
                                        else
                                            begin
                                                cs_n <= 1'b1;
                                                mosi_out_en <= 1'b0;
                                            end
                                    end
                            end
                        READ:
                            begin
                                // ready <= 1'b0;
                                mosi_out_en <= 1'b1;
                                addr <= read_addr;
                                if    (cs_n == 1'b1)
                                    begin
                                        cs_n <= 1'b0;
                                        read_done <= 1'b0;
                                        case    (mode)
                                            2'b00: 
                                                begin
                                                    // Send 13h command to read data
                                                    mosi <= READ_CMD[7];
                                                    read_count <= 7'd0;
                                                end
                                            2'b01:
                                                begin
                                                    // Send 3Ch command to read data
                                                    mosi <= DUAL_READ[7];
                                                    d_read_count <= 7'd0;
                                                end
                                            2'b10:
                                                begin
                                                    // Send 6Ch command to read data
                                                    mosi <= QUAD_READ[7];
                                                    q_read_count <= 7'd0;
                                                end
                                            default:
                                                begin
                                                    mosi <= READ_CMD[7];
                                                    read_count <= 7'd0;
                                                end
                                        endcase
                                    end

                                // mode
                                else
                                    begin
                                        case    (mode)
                                            2'b00: 
                                                begin
                                                    // Send 13h command to read data
                                                    mosi <= (read_count < 7'd7) ? READ_CMD[6 - read_count] : addr[38 - read_count];
                                                    read_count <= read_count + 7'd1;
                                                end
                                            2'b01:
                                                begin
                                                    // Send 3Ch command to read data
                                                    mosi <= (d_read_count < 7'd7) ? DUAL_READ[6 - d_read_count] : addr[38 - d_read_count];
                                                    d_read_count <= d_read_count + 7'd1;
                                                end
                                            2'b10:
                                                begin
                                                    // Send 6Ch command to read data
                                                    mosi <= (q_read_count < 7'd7) ? QUAD_READ[6 - q_read_count] : addr[38 - q_read_count];
                                                    q_read_count <= q_read_count + 7'd1;
                                                end
                                            default:
                                                begin
                                                    mosi <= (read_count < 7'd7) ? READ_CMD[6 - read_count] : addr[38 - read_count];
                                                    read_count <= read_count + 7'd1;
                                                end
                                        endcase
                                    end
                            end
                        SEND:
                            begin
                                mosi_out_en <= 1'b0;
                                write_req <= 1'b0;
                                case    (mode)
                                    2'b00: 
                                        begin
                                            if    (send_count < 5'd9)
                                                begin
											        shift_reg <= {shift_reg[6:0], io1};
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else
                                                begin
                                                    data_qspi2fifo <= shift_reg[7:0];
                                                    write_req <= 1'b1;
                                                    cs_n <= 1'b1;
                                                end
                                        end
                                    2'b01:
                                        begin
                                            if    (send_count < 5'd9)
                                                begin
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else if    (send_count < 5'd13)
                                                begin
                                                    shift_reg <= {shift_reg[5:0], io1, io0};
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else
                                                begin      
                                                    data_qspi2fifo <= shift_reg[7:0];
                                                    write_req <= 1'b1;
                                                    cs_n <= 1'b1;
                                                end
                                        end
                                    2'b10:
                                        begin
                                            if    (send_count < 5'd9)
                                                begin
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else if    (send_count < 5'd11)
                                                begin
                                                    shift_reg <= {shift_reg[3:0], io3, io2, io1, io0};
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else
                                                begin       
                                                    data_qspi2fifo <= shift_reg[7:0];
                                                    write_req <= 1'b1;
                                                    cs_n <= 1'b1;
                                                end
                                        end
                                    default:
                                        begin
                                            if    (send_count < 5'd9)
                                                begin
                                                    shift_reg <= {shift_reg[6:0], io1};
                                                    send_count <= send_count + 5'd1;
                                                end
                                            else
                                                begin
                                                    data_qspi2fifo <= shift_reg[7:0];
                                                    write_req <= 1'b1;
                                                    cs_n <= 1'b1;
                                                end
                                        end
                                endcase
                                if    (cs_n == 1'b1)
                                    begin
                                        data_written <= 1'b1;
                                    end
                            end
                        COMPLETE:
                            begin
                            // Complete the transaction
                                read_done <= 1'b1;
                                write_req <= 1'b0;
                                // ready <= 1'b1;
                                data_written <= 1'b0;
                            end
                    endcase
                end
        end

endmodule