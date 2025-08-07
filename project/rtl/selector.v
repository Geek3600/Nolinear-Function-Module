module selector #(
    parameter Bf = 1,
    parameter FIX_POINT_WIDTH = 16
) (
    input [1:0] mode, // 00:softmax 01:gelu 10:silu 11:root
    input [FIX_POINT_WIDTH - 1:0] in0, // x
    input [FIX_POINT_WIDTH - 1:0] in1, // max
    input [FIX_POINT_WIDTH - 1:0] in2, // 一阶段向二阶段传递的中间结果
    input [FIX_POINT_WIDTH - 1:0] in3, // sum
    input [FIX_POINT_WIDTH - 1:0] u,
    input [2:0] s_in,
    output [FIX_POINT_WIDTH - 1:0] out0,
    output [FIX_POINT_WIDTH - 1:0] out1
);

    wire [15:0] beta;
    parameter GELU_BETA_PLUS = 16'b0000000001000001;// 0.254 = 0.0100 0001 'h0041
    parameter GELU_BETA_SUB  = 16'b0; // 0
    parameter SiLU_BETA_PLUS = 16'b0000000000011100;// 0.110
    parameter SiLU_BETA_SUB  =  16'b1000000000011100;// -0.111

    assign beta = (mode == 1) ? in0[FIX_POINT_WIDTH - 1] ? GELU_BETA_SUB : GELU_BETA_PLUS : // FELU
                                in0[FIX_POINT_WIDTH - 1] ? SiLU_BETA_SUB : SiLU_BETA_PLUS; // SILU 选择β+-

    assign out0 = (s_in == 0) ? in0 :  // softmax 1轮 
                  (s_in == 1) ? in3 :  // softmax 2轮 
                  (s_in == 2) ? beta : // gelu silu 1轮
                  (s_in == 3) ? in2 : // gelu silu 2轮
                                in0;

    assign out1 = (s_in == 0) ? in1 : 
                  (s_in == 1) ? in2 :
                  (s_in == 2) ? in0 :
                  (s_in == 3) ? 0 : 
                                0;
    // gelu beta+ 0.254 beta- 0
    // silu beta+ 0.110 beta- -0.111

endmodule   
// 195 0001 1001 0101 1.58203125
