module ru #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)  (
    input [1:0] mode,
    input valid,
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
    // wire sign_bit;

    log2 #(
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
    )  u_log2 (
        .in(in0),
        .out(log2_out)
    );


    assign mux = s_mux ? in0 : log2_out;
    assign sub_result = (((s_mux == 0) && (s_mult == 0)) || ((s_mux == 1) && (s_mult == 3)) || ((s_mux == 1) && (s_mult == 4)) || ((s_mux == 1) && (s_mult == 5))) ? in1 - mux : mux - in1;
    // assign sign_bit = sub_result[FIX_POINT_WIDTH-1] ? 1 : 0; // 检查相减结果是否为0
    constant_mul #(
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
    )  u_constant_mul (
        .s_mult(s_mult),
        .in(sub_result),
        .out(const_mul_out)
    );

    wire [FIX_POINT_WIDTH-1:0] const_mul_out2;
    assign const_mul_out2 = ((mode == 1 || mode == 2) && valid == 0) ? 0 - const_mul_out : const_mul_out; // gelu中的-P(x)，只有1轮才需要
    assign out0 = const_mul_out2;
    
    exp2 # (
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
    ) u_exp2 (
        .in(const_mul_out2),
        .u(u),
        .out(out1)
    );
    
endmodule