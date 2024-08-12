module fifo_buffer #(
    parameter    W = 8,   // Data width
    parameter    D = 256  // Buffer depth
)(
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    read_req,
    input wire    write_req,
    input wire    [W-1:0] fifo_dataIn,
    output reg    [W-1:0] fifo_dataOut,
    output wire    empty,
    output wire    full
);

    // Internal variables
    reg    [W-1:0] fifo [D-1:0];  // max buffer size is 256 bytes
    reg    [7:0] read_counter = 8'd0; 
    reg    [7:0] write_counter = 8'd0;
    reg    [7:0] count = 8'd0;
    wire    read;
    wire    write;

    assign full = (count == D) ? 1'b1 : 1'b0;
    assign empty = (count == 0) ? 1'b1 : 1'b0;
    // Assign empty and full signals
    assign write = write_req;
    assign read = read_req; 
    // FIFO operations
    always @(posedge system_clk or negedge system_reset_n)
        begin
            if    (!system_reset_n)
                begin
                    count <= 8'd0;
                end
            else if    ((!full && write) && (!empty && read))
                begin
                    count <= count;
                end
            else if    (!full && write)
                begin
                    count <= count + 8'd1;
                end
            else if    (!empty && read)
                begin
                    count <= count - 8'd1;
                end
            else
                begin
                    count <= count;
                end
        end
    always @(posedge system_clk or negedge system_reset_n)
        begin
            if    (!system_reset_n)
                begin
                    fifo_dataOut <= 8'd0;
                end
            else
                begin
                    if    (read && !empty)
                        begin
                            fifo_dataOut <= fifo[read_counter];
                        end
                    else
                        begin
                            fifo_dataOut <= fifo_dataOut;
                        end
                end 
        end
    always @(posedge system_clk)
        begin
            if    (write && !full)
                begin
                    fifo[write_counter] <= fifo_dataIn;
                end
            else
                begin
                    fifo[write_counter] <= fifo[write_counter];
                end
        end
    always @(posedge system_clk or negedge system_reset_n)
        begin
            if    (!system_reset_n)
                begin
                    read_counter <= 8'd0;
                    write_counter <= 8'd0;
                end
            else
                begin
                    if    (read && !empty)
                        begin
                            read_counter <= read_counter + 8'd1;
                        end
                    if    (write && !full)
                        begin
                            write_counter <= write_counter + 8'd1;
                        end
                end
        end
                

endmodule