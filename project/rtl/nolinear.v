module nolinear #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 4
)  (
    input clk,
    input rst,
    input valid, // 用于启动反馈循环，也就是开启2轮
    input [1:0] mode, // 00: softmax, 01: gelu, 10:silu, 11:root
    input [DATA_NUM * FIX_POINT_WIDTH - 1:0] in,
    input [2:0] s_in,
    input s_mux,
    input [2:0] s_mult,
    input s_add,
    input en_add,
    input en_mult,
    output [DATA_NUM * FIX_POINT_WIDTH - 1:0] out
);

    // stage 1
    // max 找最大值(仅用于softmax)
    wire [FIX_POINT_WIDTH-1:0] max_out;
    wire en;
    assign en = (mode == 'b00);
    systolic_odd_even_sort # (
        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
        .DATA_NUM(DATA_NUM)
    ) u_systolic_odd_even_sort (
	    .clk(clk),
	    .rst(rst),
        .en(en),
        .in(in),
        .max_out(max_out)
    );

    // selector 
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] selector_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] selector_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage1_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage1_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] selector_in2;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] selector_in3;

    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_mux;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_out1;

    assign selector_in2 = (valid) ? stage4_out0 : 0;
    assign selector_in3 = (valid) ? {FIX_POINT_WIDTH{stage4_out1[DATA_NUM * FIX_POINT_WIDTH-1 : (DATA_NUM - 1) * FIX_POINT_WIDTH ]}} : 0;
    genvar i;
    generate
        for (i = 1; i <= DATA_NUM; i = i + 1) begin: selector
            selector #(
                .Bf(Bf),
                .FIX_POINT_WIDTH(16)
            ) u_selector (
                .mode(mode), // 0:softmax 1:gelu 2:silu 3:root
                .in0(in[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // x
                .in1(max_out), // max
                .in2(selector_in2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // ru_out0 (一阶段向二阶段传递的中间结果) 
                .in3(selector_in3[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // sum(一阶段向二阶段传递的中间结果)
                .u(stage3_out_u[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                .s_in(s_in),
                .out0(selector_out0[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                .out1(selector_out1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH])
            );
        end
    endgenerate
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage1_reg0 (clk, rst, selector_out0, stage1_out0);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage1_reg1 (clk, rst, selector_out1, stage1_out1);


    // stage 2
    // ru
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] u;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] ru_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] ru_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage2_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage2_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage2_out_u;
    genvar j;
    generate
        for (j = 1; j <= DATA_NUM; j = j + 1) begin: ru
            ru #(
                .Bf(Bf),
                .FIX_POINT_WIDTH(16)
            ) u_ru (
                // 4 input
                .in0(stage1_out0[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .in1(stage1_out1[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .s_mux(s_mux),
                .s_mult(s_mult),

                // 3 output
                .out0(ru_out0[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .out1(ru_out1[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .u(u[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH])
            );
        end
    endgenerate
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage2_reg0 (clk, rst, ru_out0, stage2_out0);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage2_reg1 (clk, rst, ru_out1, stage2_out1);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage2_reg_u (clk, rst, u, stage2_out_u);


    // stage 3
    // add
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] add_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] add_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage3_mux;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage3_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage3_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage3_out_u;
    genvar a;
    generate
        for (a = 1; a <= DATA_NUM; a = a + 1) begin: add
            if (a == 1) begin
                add #(
                    .Bf(Bf),
                    .FIX_POINT_WIDTH(16)
                ) u_add (
                    // 4 input 
                    .in0(stage2_out1[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .in1(16'b0),
                    .u(stage2_out_u[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .s_add(s_add),

                    // 2 output 
                    .out0(add_out0[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .out1(add_out1[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH])
                );
            end
            else begin
                add #(
                    .Bf(Bf),
                    .FIX_POINT_WIDTH(16)
                ) u_add (
                    // 4 input 
                    .in0(stage2_out1[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .in1(add_out1[(a-1)*FIX_POINT_WIDTH-1:(a-2)*FIX_POINT_WIDTH]),
                    .u(stage2_out_u[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .s_add(s_add),

                    // 2 output 
                    .out0(add_out0[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH]),
                    .out1(add_out1[a*FIX_POINT_WIDTH-1:(a-1)*FIX_POINT_WIDTH])
                );
            end
        end
    endgenerate
    assign stage3_mux = (en_add) ? ru_out1 : add_out0;
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage3_reg0 (clk, rst, stage2_out0, stage3_out0);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage3_reg1 (clk, rst, stage3_mux, stage3_out1);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage3_reg_u (clk, rst, stage2_out_u, stage3_out_u);

    // stage 4
 
    genvar k;
    generate
        for (k = 1; k <= DATA_NUM; k = k + 1) begin: stage4 
            assign stage4_mux[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] = (en_mult) ? stage3_out1[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] : 
                            (stage3_out1[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] * in[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH]);
        end
    endgenerate
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage4_reg0 (clk, rst, stage3_out0, stage4_out0);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage4_reg1 (clk, rst, stage4_mux, stage4_out1);

    assign out = stage4_out1;
endmodule