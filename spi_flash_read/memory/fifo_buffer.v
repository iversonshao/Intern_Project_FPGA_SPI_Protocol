module fifo_buffer #(
    parameter    W = 8,   // Data width
    parameter    D = 256  // Buffer depth
)(
    input wire    system_clk,
    input wire    system_reset_n,
    input wire    read_req,
    input wire    write_req,
    input wire    enable,
    input wire    [W-1:0] fifo_dataIn,
    output reg    [W-1:0] fifo_dataOut,
    output wire    empty,
    output wire    full
);

    // Internal variables
    reg    [W-1:0] fifo [0:D-1];  // max buffer size is 256 bytes
    // reg    [7:0] read_counter;
    // reg    [7:0] write_counter;
    reg    [W:0] count;
    reg    [W-1:0] read_counter;
    reg    [W-1:0] write_counter;
    // Assign empty and full signals

    assign full = (count == D) ? 1 : 0;
    assign empty = (count == 0) ? 1 : 0;
    // FIFO operations

    always @(posedge system_clk or negedge system_reset_n) 
        begin
            if    (!system_reset_n) 
                begin
                    read_counter <= 8'b0;
                    write_counter <= 8'b0;
                    count <= 9'b0;
                end
            else if    (enable)
                begin
                    if    (read_req && !empty)
                        begin
                            fifo_dataOut <= fifo[read_counter];
                            read_counter <= read_counter + 1'b1;
                            count <= count - 1'b1;
                        end
                    if    (write_req && !full)
                        begin
                            fifo[write_counter] <= fifo_dataIn;
                            write_counter <= write_counter + 1'b1;
                            count <= count + 1'b1;
                        end
                    if    (read_counter == D)
                        begin
                            read_counter <= 8'b0;
                        end
                    if    (write_counter == D)
                        begin
                            write_counter <= 8'b0;
                        end
                end
        end

endmodule