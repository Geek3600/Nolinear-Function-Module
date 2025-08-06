`timescale  1ns/1ns

module  tb_exp2();
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

    reg [15:0] in;
    wire [15:0] u;
    wire [15:0] out;

    initial begin
        in = 16'b0000000110000000;
    end

    exp2 #(
        .Bf(8),
        .FIX_POINT_WIDTH(16)
    )  u_exp2 (
        .in(in),
        .u(u),
        .out(out)
    );
    initial begin
        $fsdbDumpfile("tb_exp2.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule
