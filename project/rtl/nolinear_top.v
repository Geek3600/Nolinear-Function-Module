module nolinear_top #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 16
)  (
    input clk,
    input rst,
    input en,
    input [1:0] mode, // 00: softmax, 01: gelu, 10:silu, 11:root
    // input [DATA_NUM * FIX_POINT_WIDTH - 1:0] in,
    input [DATA_NUM * 8 - 1:0] in,
    output [DATA_NUM * FIX_POINT_WIDTH - 1:0] out
);  
    wire max_en;
    wire [2:0] s_in;
    wire s_mux;
    wire [2:0] s_mult;
    wire s_add;
    wire en_add;
    wire en_mult;
    wire valid;
    wire finish;


    wire [DATA_NUM * FIX_POINT_WIDTH - 1:0] in_fixed_vec;
    genvar i;
    generate
        for (i = 0; i < DATA_NUM; i = i + 1) begin : to_fixed
            assign in_fixed_vec[i*FIX_POINT_WIDTH +: FIX_POINT_WIDTH] = {in[i*8 +: 8], 8'b0};
        end
    endgenerate

    controller #(
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
        .DATA_NUM(DATA_NUM)
    ) u_controller (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode), // 00: softmax, 01: gelu, 10:silu, 11:root
        .valid(valid), // 用于启动反馈循环，也就是开启2轮
        .max_en(max_en),
        .s_in(s_in),
        .s_mux(s_mux),
        .s_mult(s_mult),
        .s_add(s_add),
        .en_add(en_add),
        .en_mult(en_mult),
        .finish(finish)
    );

    wire [DATA_NUM * FIX_POINT_WIDTH - 1:0] nolinear_out;
    nolinear #(
        .Bf(Bf),
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
        .DATA_NUM(DATA_NUM)
    )  u_nolinear (
        .clk(clk),
        .rst(rst),
        .valid(valid), // 用于启动反馈循环，也就是开启2轮
        .mode(mode),  // 00: softmax, 01: gelu, 10:silu, 11:root
        .max_en(max_en),
        .in(in_fixed_vec),
        .s_in(s_in),
        .s_mux(s_mux),
        .s_mult(s_mult),
        .s_add(s_add),
        .en_add(en_add),
        .en_mult(en_mult),
        .out(nolinear_out)
    );
    assign out = (finish == 1)? nolinear_out : 0;
endmodule

