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
    output reg [DATA_NUM * FIX_POINT_WIDTH - 1:0] out
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
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] selector_u;

    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage3_out_u;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_mux;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_out0;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_out1;
    wire [DATA_NUM * FIX_POINT_WIDTH-1:0] stage4_out_u;

    wire [DATA_NUM * 3 - 1: 0] s_mult_d;

    // softmax和gelu的2阶段需要用到不同
    // assign selector_in2 = (valid) ? stage4_out0 : 0;
    assign selector_in2 = (valid) ? (mode == 0) ? stage4_out0 : stage4_out1 : 0;

    // 把softmax一阶段的求和分发到所有端口，用于二阶段计算
    assign selector_in3 = (valid) ? {FIX_POINT_WIDTH{stage4_out1[DATA_NUM * FIX_POINT_WIDTH-1 : (DATA_NUM - 1) * FIX_POINT_WIDTH ]}} : 0;
    assign selector_u = (valid) ? stage3_out_u : 0;
    genvar i;
    generate
        for (i = 1; i <= DATA_NUM; i = i + 1) begin: selector
            selector #(
                .Bf(Bf),
                .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
            ) u_selector (
                .mode(mode), // 0:softmax 1:gelu 2:silu 3:root
                .in0(in[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // x
                .in1(max_out), // max
                .in2(selector_in2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // ru_out0 (一阶段向二阶段传递的中间结果) 
                .in3(selector_in3[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]), // sum(一阶段向二阶段传递的中间结果)
                .u(selector_u[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
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
                .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
            ) u_ru (
                // 5 input
                .valid(valid),
                .mode(mode),
                .in0(stage1_out0[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .in1(stage1_out1[j*FIX_POINT_WIDTH-1:(j-1)*FIX_POINT_WIDTH]),
                .s_mux(s_mux),
                .s_mult(s_mult_d[j*3-1:(j-1)*3]),

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
    genvar a;
    generate
        for (a = 1; a <= DATA_NUM; a = a + 1) begin: add
            if (a == 1) begin
                add #(
                    .Bf(Bf),
                    .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
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
                    .FIX_POINT_WIDTH(FIX_POINT_WIDTH)
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
    wire [2 * DATA_NUM * FIX_POINT_WIDTH-1:0] multiply;
    genvar k;
    generate
        for (k = 1; k <= DATA_NUM; k = k + 1) begin: stage4 
            assign multiply[2*k*FIX_POINT_WIDTH-1:2*(k-1)*FIX_POINT_WIDTH] = stage3_out1[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] * in[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH]; // gelu和silu最后与输入相乘
            assign stage4_mux[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] = (en_mult) ? stage3_out1[k*FIX_POINT_WIDTH-1:(k-1)*FIX_POINT_WIDTH] : multiply[2*k*FIX_POINT_WIDTH + Bf -1:2*(k-1)*FIX_POINT_WIDTH + Bf];
        end
    endgenerate
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage4_reg0 (clk, rst, stage3_out0, stage4_out0);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage4_reg1 (clk, rst, stage4_mux, stage4_out1);
    register # (.DATASIZE(DATA_NUM * FIX_POINT_WIDTH)) u_stage4_reg_u (clk, rst, stage3_out_u, stage4_out_u);


    // assign out = stage4_out1;


    reg [DATA_NUM] s;
    genvar m;
    generate
        for (m = 1; m <= FIX_POINT_WIDTH; m = m + 1) begin: skip
            wire signed [(FIX_POINT_WIDTH - Bf) - 1 : 0] input_int;
            assign input_int = in[m * FIX_POINT_WIDTH - 1 : (m-1) * FIX_POINT_WIDTH + Bf]; 
            always @(*) begin
                if (mode == 1) begin // gelu
                    if (input_int >= 8'sd4 || input_int <= -8'sd4) begin
                    // if (input_int[m*(FIX_POINT_WIDTH-Bf)-1:(m-1)*(FIX_POINT_WIDTH-Bf)] >= 8'sd4 || input_int[m*(FIX_POINT_WIDTH-Bf)-1:(m-1)*(FIX_POINT_WIDTH-Bf)] <= -8'sd4) begin
                        s[m-1] = 1;
                        out[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH] = in[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH];
                    end
                    else begin 
                        s[m-1] = 0;
                        out[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH] = stage4_out1[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH];
                    end
                end
                else if (mode == 2) begin // silu
                    if (input_int >= 8'sd9 || input_int <= -8'sd9) begin
                    // if (input_int[m*(FIX_POINT_WIDTH-Bf)-1:(m-1)*(FIX_POINT_WIDTH-Bf)] >= 8'sd9 || input_int[m*(FIX_POINT_WIDTH-Bf)-1:(m-1)*(FIX_POINT_WIDTH-Bf)] <= -8'sd9) begin
                        s[m-1] = 1;
                        out[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH] = in[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH];
                    end
                    else begin 
                        s[m-1] = 0;
                        out[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH] = stage4_out1[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH];
                    end
                end
                else 
                    s[m-1] = 0;
                    out[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH] = stage4_out1[m*FIX_POINT_WIDTH-1:(m-1)*FIX_POINT_WIDTH];
            end
        end
    endgenerate


    reg [DATA_NUM-1:0] input_sign;
    genvar n;
    generate 
        for (n = 1; n <= DATA_NUM; n = n + 1) begin: silu_const_mul
         // 描述 input_sign 的连接关系
        assign input_sign[n-1] = in[n*FIX_POINT_WIDTH-1];
        // 描述 s_mult_d 的连接关系，用一个 assign 语句和三元运算符实现 if/else 的逻辑
        assign s_mult_d[n*3-1:(n-1)*3] = (mode == 2) ? ((valid == 1) ? 0 : input_sign[n-1] ? 3'd5 : 3'd4) : s_mult;
    end
    endgenerate
endmodule

