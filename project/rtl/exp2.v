module exp2 # (
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)(
    // input [1:0] mode, // 00: softmax, 01: gelu, 10:silu, 11:root
    input [FIX_POINT_WIDTH - 1:0] in,
    output [FIX_POINT_WIDTH - 1:0] u,
    output [FIX_POINT_WIDTH - 1:0] out
);

    // 计算softmax时输入总是负数
    wire [FIX_POINT_WIDTH - 1:0] v; // 小数部分，保持定点数形式
    wire [FIX_POINT_WIDTH - Bf - 1 : 0] shift_len; // 移位长度，也就是u

    // 如果输入是个负数，就需要将补码转成原码
    assign shift_len = (in[FIX_POINT_WIDTH-1] == 1) ? (~(in[FIX_POINT_WIDTH - 1 : Bf] - 1)) : in[FIX_POINT_WIDTH - 1 : Bf];
    
    // 提取整数，同时保持16位定点数格式 
    // assign u = {in[FIX_POINT_WIDTH - 1 : Bf], {Bf{1'b0}}};
    assign v = {{(FIX_POINT_WIDTH - Bf){1'b0}}, in[Bf - 1 : 0]};

    // 如果输入是个负数，就需要将补码转成原码，然后右移
    assign out = (in[FIX_POINT_WIDTH-1] == 1) ? ((1 << Bf) + v) >> shift_len : ((1 << Bf) + v) << shift_len;
endmodule
//fbb0
//  01b0 >> 3