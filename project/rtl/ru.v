module ru #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)  (
    input [FIX_POINT_WIDTH-1:0] in0,
    input [FIX_POINT_WIDTH-1:0] in1,
    input s_mux,
    input [2:0] s_mult,
    output [FIX_POINT_WIDTH-1:0] out0,
    output [FIX_POINT_WIDTH-1:0] out1,
    output [FIX_POINT_WIDTH-1:0] u
);

    wire [FIX_POINT_WIDTH-1:0] log2_out;
    wire [FIX_POINT_WIDTH-1:0] mux;
    wire [FIX_POINT_WIDTH-1:0] sub_result;
    wire [FIX_POINT_WIDTH-1:0] const_mul_out;
    log2 #(
        .Bf(8),
        .FIX_POINT_WIDTH(16)
    )  u_log2 (
        .in(in0),
        .out(log2_out)
    );


    assign mux = s_mux ? in0 : log2_out;

    assign sub_result = ((s_mux == 0) && (s_mult == 0)) ? in1 - mux : mux - in1;
    constant_mul #(
        .Bf(8),
        .FIX_POINT_WIDTH(16)
    )  u_constant_mul (
        .s_mult(s_mult),
        .in(sub_result),
        .out(const_mul_out)
    );

    assign out0 = const_mul_out;
    
    exp2 # (
        .Bf(8),
        .FIX_POINT_WIDTH(16)
    ) u_exp2 (
        .in(const_mul_out),
        .u(u),
        .out(out1)
    );
    
endmodule