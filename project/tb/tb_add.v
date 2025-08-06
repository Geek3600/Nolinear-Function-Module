`timescale  1ns/1ns

module  tb_add();
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
    reg [15:0] u;
    reg s_add;
    wire [15:0] out0;
    wire [15:0] out1;

    initial begin
        in0 = 0;
        in1 = 0;
        u = 0;
        s_add = 0;
        #10;
        s_add = 1;
        in0 = 1;
        in1 = 2;
    end

    add #(
        .Bf(1),
        .FIX_POINT_WIDTH(16)
    )  u_add (
        .in0(in0),
        .in1(in1),
        .u(u),
        .s_add(s_add),
        .out0(out0),
        .out1(out1)
    );
    initial begin
        $fsdbDumpfile("tb_add.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule
