`timescale  1ns/1ns

module  tb_selector();
    reg clk;
    reg rst;

    initial begin
        clk    = 1'b0;
        rst <= 1'b1;
        #20
        rst <= 1'b0;
        #100 $finish;
    end

    always begin
        #10 clk <= ~clk;
    end

    reg [15:0] in0;
    reg [15:0] in1;
    reg [15:0] in2;
    reg [15:0] in3;
    reg [15:0] u;
    reg [1:0]  mode;
    reg [2:0]  s_in;
    wire [15:0] out0;
    wire [15:0] out1;

    initial begin
        in0 = 1;
        in1 = 2;
        in2 = 3;
        in3 = 4;
        u = 5;
        mode = 0;
        s_in = 0;
        #10;
        s_in = 1;
        #10;
        s_in = 2;
        #10;
        s_in = 3;
        #10;
        s_in = 4;
    end

    selector #(
        .Bf(1),
        .FIX_POINT_WIDTH(16)
    )  u_selector (
        .mode(mode),
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .u(u),
        .s_in(s_in),
        .out0(out0),
        .out1(out1)
    );
    initial begin
        $fsdbDumpfile("tb_selector.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule
