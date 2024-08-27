`timescale 1 ns/ 1 ns
module fifo_buffer_vlg_tst();
// constants
parameter W = 8;    // Data width
parameter D = 256;  // Buffer depth

// test vector input registers
reg    [W-1:0] fifo_dataIn;
reg    read_req;
reg    system_clk;
reg    system_reset_n;
reg    write_req;
// wires
wire    empty;
wire    [W-1:0] fifo_dataOut;
wire    full;

// assign statements (if any)
fifo_buffer #(
    .W(W),
    .D(D)
) uut (
// port map - connection between master ports and signals/registers   
    .empty(empty),
    .fifo_dataIn(fifo_dataIn),
    .fifo_dataOut(fifo_dataOut),
    .full(full),
    .read_req(read_req),
    .system_clk(system_clk),
    .system_reset_n(system_reset_n),
    .write_req(write_req)
);

//generate clock
always #10 system_clk = ~system_clk;

initial
    begin
        system_clk = 1'b0;
        system_reset_n = 1'b0;
        write_req = 1'b0;
        read_req = 1'b0;
        fifo_dataIn = 8'h00;
        $display("Running testbench");

        // Reset
        #100;
        system_reset_n = 1;
        #20;

        // Write data
        $display("Writing data to buffer");
        #20;
        write_req = 1'b1;
        fifo_dataIn = 8'h00;
        #20;
        write_req = 1'b0;

        #20;
        write_req = 1'b1;       
        fifo_dataIn = 8'h01;
        #20;
        write_req = 1'b0;

        #20;
        write_req = 1'b1;
        fifo_dataIn = 8'h02;
        #20;
        write_req = 1'b0;

        #20;
        write_req = 1'b1;
        fifo_dataIn = 8'h03;
        #20;
        write_req = 1'b0;

        #20;
        write_req = 1'b1;
        fifo_dataIn = 8'h04;
        #20;
        write_req = 1'b0;

        
        // Read data

        $display("Reading data from buffer");
        #20;
        read_req = 1'b1;
        #20;
        read_req = 1'b0;
        #20;
        $display("FIFO Data Out: %h", fifo_dataOut);

        #20;
        read_req = 1'b1;
        #20;
        read_req = 1'b0;

        #20;
        $display("FIFO Data Out: %h", fifo_dataOut);

        #20;
        read_req = 1'b1;
        #20;
        read_req = 1'b0;

        #20;
        $display("FIFO Data Out: %h", fifo_dataOut);

        #20;
        read_req = 1'b1;
        #20;
        read_req = 1'b0;

        #20;
        $display("FIFO Data Out: %h", fifo_dataOut);

        #20;
        read_req = 1'b1;
        #20;
        read_req = 1'b0;

        #20;
        $display("FIFO Data Out: %h", fifo_dataOut);
    
        #100;
        $stop;
    end                                                   
endmodule