`timescale 1 ns/ 1 ns

module top_read_vlg_tst();

reg    CLK_25M_CKMNG_MAIN_PLD;
reg    PWRGD_P1V2_MAX10_AUX_PLD_R;

reg    [31:0] end_addr;
reg    [1:0] mode;
reg    read_req;
reg    [31:0] start_addr;
reg    start_flag;
reg    switch_die_need;

wire    busy;
wire    completed;

top_read uut (
    .PWRGD_P1V2_MAX10_AUX_PLD_Rt(PWRGD_P1V2_MAX10_AUX_PLD_R),
    .busy(busy),
    .completed(completed),
    .end_addr(end_addr),
    .iCLK_25M_CKMNG_MAIN_PLD(CLK_25M_CKMNG_MAIN_PLD),
    .mode(mode),
    .read_req(read_req),
    .start_addr(start_addr),
    .start_flag(start_flag),
    .switch_die_need(switch_die_need)
);

always #20 CLK_25M_CKMNG_MAIN_PLD = ~CLK_25M_CKMNG_MAIN_PLD; // 25MHz

initial begin
    CLK_25M_CKMNG_MAIN_PLD = 0;
    PWRGD_P1V2_MAX10_AUX_PLD_R = 0;
    end_addr = 0;
    mode = 0;
    read_req = 0;
    start_addr = 0;
    start_flag = 0;
    switch_die_need = 0;
    
    #100;
    PWRGD_P1V2_MAX10_AUX_PLD_R = 1;
    #100;

    $display("Test 1: Standard mode read");
    start_addr = 32'h00000000;
    end_addr = 32'h0000000F;
    mode = 2'b00;
    start_flag = 1;
    #40;
    wait(completed);
    start_flag = 0;
    #100;

    $display("Test 2: Dual mode read");
    start_addr = 32'h00000100;
    end_addr = 32'h0000010F;
    mode = 2'b01;
    start_flag = 1;
    #40;
    wait(completed);
    start_flag = 0;
    #100;

    
    $display("Test 3: Quad mode read");
    start_addr = 32'h00000200;
    end_addr = 32'h0000020F;
    mode = 2'b10;
    start_flag = 1;
    #40;
    wait(completed);
    start_flag = 0;
    #100;

    $display("Test 4: Die switch");
    start_addr = 32'h01FFFFF0;
    end_addr = 32'h02000010;
    mode = 2'b00;
    switch_die_need = 1;
    start_flag = 1;
    #40;
    wait(completed);
    start_flag = 0;
    #100;

    $display("Test 5: FIFO full test");
    start_addr = 32'h00000300;
    end_addr = 32'h000003FF;
    mode = 2'b00;
    start_flag = 1;
    #40;
    force uut.f1.full = 1'b1;
    #100;
    release uut.f1.full;
    wait(completed);
    start_flag = 0;
    #100;

    $display("All tests completed");
    $stop;
end

always @(posedge CLK_25M_CKMNG_MAIN_PLD) begin
    if (busy) $display("Time %t: Busy", $time);
    if (completed) $display("Time %t: Completed", $time);
end

endmodule