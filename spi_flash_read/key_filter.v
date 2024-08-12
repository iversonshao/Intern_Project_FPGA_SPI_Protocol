module key_filter #(
    parameter    CNT_MAX = 20'd999_999 // 50MHz x 20ms = 1_000_000 
)(
    input wire    system_clk, // 50MHz
    input wire    system_reset_n,
    input wire    key_in,
    output reg    key_flag
);
    reg    [19:0] cnt_20ms;
always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                cnt_20ms <= 20'd0;
            end
        else if    (key_in == 1'b1)
            begin
                cnt_20ms <= 20'd0;
            end
        else if    (cnt_20ms == CNT_MAX && key_in == 1'b0)
            begin
                cnt_20ms <= cnt_20ms;
            end
        else
            begin
                cnt_20ms <= cnt_20ms + 20'd1;
            end
    end

always @(posedge system_clk or negedge system_reset_n)
    begin
        if    (!system_reset_n)
            begin
                key_flag <= 1'b0;
            end
        else if    (cnt_20ms == CNT_MAX - 20'd1)
            begin
                key_flag <= 1'b1;
            end
        else
            begin
                key_flag <= 1'b0;
            end
    end
endmodule