module key_filter(
    input wire    system_clk,
    input wire    key_in,
    output wire    key_flag
);
reg    [20:0] cnt_20ms;
reg    key_in_r1, key_in_r2, key_out;
assign key_flag = ~cnt_20ms [20];
always @(posedge system_clk)
    begin
		 key_in_r1 <= key_in;
		 key_in_r2 <= key_in_r1;
		 key_out <= key_in_r2;
    end

always @(posedge system_clk)
    begin
        if    (key_out)
            begin
                cnt_20ms <= 20'b0;
            end
        else if    (!cnt_20ms[20])
            begin
                cnt_20ms <= cnt_20ms + 1;
            end
    end
endmodule