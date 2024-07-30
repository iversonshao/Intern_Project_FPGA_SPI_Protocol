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
    reg    [7:0] count;
    reg    [W-1:0] fifo [D-1:0];  // max buffer size is 256 bytes
    reg    [7:0] read_counter, write_counter;
    wire    read;
    wire    write;
    // Assign empty and full signals
    assign empty = (count == 8'd0);
    assign full = (count == D);
    assign write = write_req;
    assign read = read_req; 
    // FIFO operations
    always @(posedge system_clk or negedge system_reset_n)
        begin
            if (!system_reset_n)
                begin
                    read_counter <= 8'd0;
                    write_counter <= 8'd0;
                    count <= 8'd0;
                    fifo_dataOut <= 8'd0;
                end
            else
                begin
                    // When full, keep reading out data
                    if (full)
                        begin
                            fifo_dataOut <= fifo[read_counter];
                            read_counter <= (read_counter == D - 1) ? 8'd0 : read_counter + 8'd1;
                            count <= count - 8'd1;
                        end
                    else
                        begin
                            // Normal write operation
                            if (write && !full)
                                begin
                                    fifo[write_counter] <= fifo_dataIn;
                                    write_counter <= (write_counter == D - 1) ? 8'd0 : write_counter + 8'd1;
                                    count <= count + 8'd1;
                                end

                            // Normal read operation
                            if (read && !empty)
                                begin
                                    fifo_dataOut <= fifo[read_counter];
                                    read_counter <= (read_counter == D - 1) ? 8'd0 : read_counter + 8'd1;
                                    count <= count - 8'd1;
                                end
                        end
                end
        end

endmodule