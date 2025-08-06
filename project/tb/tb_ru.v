`timescale  1ns/1ns

module  tb_ru();
    reg clk;
    reg rst;

    initial begin
        clk    = 1'b0;
        rst <= 1'b1;
        #20
        rst <= 1'b0;
        #10000 $finish;
    end

    always begin
        #10 clk <= ~clk;
    end

    reg [15:0] in0;
    reg [15:0] in1;
    reg        s_mux;
    reg [2:0]  s_mult;
    wire [15:0] u;
    wire [15:0] out0;
    wire [15:0] out1;

    initial begin
        in0 = 0;
        in1 = 0;
        s_mux = 0;
        s_mult = 0;
        #10;
        s_mux = 0;
        s_mult = 1;
        in0 = 16'b0000010000000000;
        in1 = 0;
    end

    ru #(
        .Bf(8),
        .FIX_POINT_WIDTH(16)
    )  u_ru (
        .in0(in0),
        .in1(in1),
        .s_mux(s_mux),
        .s_mult(s_mult),
        .out0(out0),
        .out1(out1),
        .u(u)
    );
    initial begin
        $fsdbDumpfile("tb_ru.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule
