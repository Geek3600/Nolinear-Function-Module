`timescale  1ns/1ns

module  tb_nolinear();
    reg clk;
    reg rst;

    initial begin
        clk    = 1'b0;
        rst <= 1'b1;
        #20
        rst <= 1'b0;
        #1000 $finish;
    end

    always begin
        #10 clk <= ~clk;
    end

    reg [1:0] mode; // 00: softmax, 01: gelu/silu, 10:root
    reg [4 * 16 - 1:0] in;
    reg [2:0] s_in;
    reg s_mux;
    reg [2:0] s_mult;
    reg s_add;
    reg en_add;
    reg en_mult;
    reg valid;
    wire [4 * 16 - 1:0] out;

    initial begin
        mode = 'b00;
        in = 0;
        s_in = 0;
        s_mux = 0;
        s_mult = 0;
        s_add = 0;
        en_add = 0;
        en_mult = 0;
        valid = 0;

        // #10; // softmax 1轮
        // in = 'h0100020003000400;
        // s_in = 0;
        // valid = 0;
        // s_mux = 1;
        // s_mult = 2;
        // s_add = 1;
        // en_mult = 1;
        // en_add = 0;
        
        // #500; // 2轮
        // valid = 1;
        // s_in = 1;
        // s_mux = 0;
        // s_mult = 0;
        // s_add = 1; // softmax 2轮，add不管
        // en_mult = 1;
        // en_add = 1;

        #10;
        in = 'h0100020003000400;
        mode = 1;
        s_in = 2; // gelu/silu 1轮
        valid = 0;
        s_mux = 1;
        s_mult = 3;
        s_add = 0; 
        en_mult = 1;
        en_add = 0;
    end

    nolinear #(
        .Bf(8),
        .FIX_POINT_WIDTH(16),
        .DATA_NUM(4)
    )  u_nolinear (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .mode(mode), // 00: softmax, 01: gelu/silu, 10:root
        .in(in),
        .s_in(s_in),
        .s_mux(s_mux),
        .s_mult(s_mult),
        .s_add(s_add),
        .en_add(en_add),
        .en_mult(en_mult),
        .out(out)
    );
    initial begin
        $fsdbDumpfile("tb_nolinear.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule
