`timescale  1ns/1ns

module  tb_nolinear();
    reg clk;
    reg rst;

    initial begin
        clk <= 1'b0;
        rst <= 1'b1;
        #10
        rst <= 1'b0;
        #5000 $finish;
    end

    always begin
        #5 clk <= ~clk;
    end
    parameter FIX_POINT_WIDTH = 16;
    parameter DATA_NUM = 32;
    parameter Bf = 8;

    reg [1:0] mode; // 00: softmax, 01：gelu 10：silu, 11:root
    reg [DATA_NUM * FIX_POINT_WIDTH - 1:0] in;
    reg en;
    // reg [2:0] s_in;
    // reg s_mux;
    // reg [2:0] s_mult;
    // reg s_add;
    // reg en_add;
    // reg en_mult;
    // reg valid;
    wire [DATA_NUM * FIX_POINT_WIDTH - 1:0] out;

    initial begin
        en = 0;
        mode = 'b00;
        in = 0; 
        #10;
        en = 1;
        mode = 'b10;
        // in = 'h0100020003000400;
        in = 'h0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20;
        // mode = 'b00;
        // in = 0;
        // s_in = 0;
        // s_mux = 0;
        // s_mult = 0;
        // s_add = 0;
        // en_add = 0;
        // en_mult = 0;
        // valid = 0;

        // // stage1 selector 4: out0:100, out1:400
        // //
        // #10; // softmax 1轮
        // in = 'h0100020003000400;
        // // in = 'h0100020003000400050006000700080009000A000B000C000D000E000F0010001100120013001400150016001700180019001A001B001C001D001E001F002000;
        // // in = 'h0100020003000400050006000700080009000A000B000C000D000E000F001000;
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
        // en_add = 1; // ru4的结果是0008

        // #10; // gelu 1轮
        // in = 'h0200020002000200;
        // // in = 'h0900090009000900;
        // // in = {1'b0, 16'h0001, 1'b0, 16'h0002, 1'b0, 16'h0003, 1'b0, 16'h0004};
        // mode = 1;
        // s_in = 2; // gelu/silu 1轮
        // valid = 0;
        // s_mux = 1;
        // s_mult = 4;
        // s_add = 0; 
        // en_mult = 1;
        // en_add = 0;

        // #500; // gelu 2轮
        // valid = 1;
        // s_in = 3;
        // s_mux = 0;
        // s_mult = 0;
        // s_add = 1; // gelu/silu 2轮，add不管
        // en_mult = 0;
        // en_add = 1;


        // #10; // root 
        // in = 'h0400090010001900;
        // mode = 1;
        // s_in = 2; 
        // valid = 0;
        // s_mux = 0;
        // s_mult = 1;
        // s_add = 0; 
        // en_mult = 1;
        // en_add = 0;
    end

    // nolinear #(
    //     .Bf(Bf),
    //     .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
    //     .DATA_NUM(DATA_NUM)
    // )  u_nolinear (
    //     .clk(clk),
    //     .rst(rst),
    //     .valid(valid),
    //     .mode(mode), // 00: softmax, 01: gelu/silu, 10:root
    //     .in(in),
    //     .s_in(s_in),
    //     .s_mux(s_mux),
    //     .s_mult(s_mult),
    //     .s_add(s_add),
    //     .en_add(en_add),
    //     .en_mult(en_mult),
    //     .out(out)
    // );
    nolinear_top #(
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
        .DATA_NUM(DATA_NUM)
    )  u_nolinear_top (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode), // 00: softmax, 01: gelu, 10:silu, 11:root
        .in(in),
        .out(out)
    ); 
    initial begin
        $fsdbDumpfile("tb_nolinear.fsdb");
        $fsdbDumpvars("+all");
    end

// softmax:
// stage1 out0: 0100 0200 0300 0400
// stage1 out1: 0400 0400 0400
// x - max = 1 - 4 = fd00
// xlog2e = fbb0
// exp2(xlog2e) = 000d 0000 1101
// sum = 0195
// l = log2(sum) = 
// x~ = xlog2e - l = 
// exp2(x~) = 0008

endmodule
