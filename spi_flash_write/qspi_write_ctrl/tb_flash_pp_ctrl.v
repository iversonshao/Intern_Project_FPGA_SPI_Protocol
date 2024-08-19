`timescale 1 ns/ 1 ns
module flash_pp_ctrl_vlg_tst();

// constants                                           
parameter CLK_PERIOD = 20; // 50MHz clock
// wire define
reg    [31:0] addr;
reg    key;
reg    [7:0] pp_num;
reg    [7:0] data;
reg    system_clk;
reg    system_reset_n;
// wires                                               
wire    cs_n;
wire    io0;
wire    spi_clk;
wire    pp_done;

reg    [7:0] romA [0:255]; // 256B
integer i;
integer byte_count;
// assign statements (if any)             
flash_pp_ctrl uut (
// port map - connection between master ports and signals/registers   
 .addr(addr),
 .cs_n(cs_n),
 .key(key),
 .io0(io0),
 .pp_num(pp_num),
 .spi_clk(spi_clk),
 .system_clk(system_clk),
 .system_reset_n(system_reset_n),
    .data(data),
    .pp_done(pp_done)
);

always
    begin
        #(CLK_PERIOD/2) system_clk = ~system_clk;
    end
initial
    begin
        for (i = 0; i < 256; i = i + 1)
            begin
                romA[i] = 8'b00010000 + i;
            end
    end
        
initial
    begin
        $display("Running testbench");
        system_reset_n = 0;
        system_clk = 0;
        key = 0;
        addr = 32'h00000000;
        pp_num = 8'd255;

        #100 system_reset_n = 1;
        #100;

        $display("Time %0t: MOSI = %b", $time, io0);
        addr = 32'h00001000;
        key = 1;
        #20 key = 0;

        #((256 + 11) * 32 * CLK_PERIOD + 1000) $finish;
    end

always @(posedge system_clk)
    begin
        data <= romA[byte_count];
        if    (byte_count < 255)
            begin
                byte_count <= byte_count + 1;
            end
        else
            begin
                byte_count <= 0;
            end
    end

endmodule