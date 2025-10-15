module constant_mul #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)  (
    input [2:0] s_mult,
    input signed [FIX_POINT_WIDTH - 1:0] in,
    output signed [FIX_POINT_WIDTH - 1:0] out
);

    // 0 1 = 1
    // 1 0.5 = 0.1
    // 2 log2e = 1.011100 01 = 1.4427
    // 3 gelu α+-log2e = 10.1001 0000 = 2.56250000
    // 4 silu α+log2e = 1.0110 1100 = 1.4225022
    // 5 silu α-log2e = 1.000011 00 = 1.0459575
    
    // wire signed [FIX_POINT_WIDTH - 1:0] a;
    // wire signed [FIX_POINT_WIDTH - 1:0] b;
    // wire signed [FIX_POINT_WIDTH - 1:0] c;
    // assign a = (in >>> 2);
    // assign b = (in >>> 3);
    // assign c = (in >>> 4);

    // >>> 是算术右移，需要配置signed类型
    assign out = (s_mult == 0) ? in : // 1
                 (s_mult == 1) ? in >> 1 : // 0.5
                 (s_mult == 2) ? in + (in >>> 2) + (in >>> 3) + (in >>> 4) : //log2e 约等于 1.4427 约= 1.011100 = 1.4375
                //  (s_mult == 2) ? in + (in >>> 2) + (in >>> 3) + (in >>> 4) + (in >>> 8): //log2e 约等于 1.4427 约= 1.01110001 = 1.44140625
                 (s_mult == 3) ? (in << 1) + (in >> 1) + (in >> 4) : // gelu α+-log2e
                 (s_mult == 4) ? in + (in >>> 2) + (in >>> 3) + (in >>> 5) + (in >>> 6):  // silu α+log2e
                                 in + (in >>> 5) + (in >>> 6); // silu α-log2e
endmodule

// fd00 1111 1101 0000 0000 
//      0011 1111 0100 0000
//      0001 1111 1010 0000
//      0000 1111 1101 0000
// fd00
