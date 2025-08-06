module systolic_odd_even_sort # (
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 1 
) (
	input clk,
	input rst,
    input en,
    input  [DATA_NUM*FIX_POINT_WIDTH-1:0] in,
    output [FIX_POINT_WIDTH-1:0] max_out 
);

    wire even_SL;
    wire even_SR;
    wire odd_SL;
    wire odd_SR;

    wire even_RL;
    wire even_RR;
    wire odd_RL;
    wire odd_RR;

    wire odd_cmp_en;
    wire even_cmp_en;
    wire write_enable;

    sort_controller u_sort_controller(
        .clk(clk),
        .rst(rst),
        .en(en),
        .write_enable(write_enable),  // 排序前存储待排序数据
        .even_SL(even_SL),
        .even_SR(even_SR),
        .odd_SL(odd_SL),
        .odd_SR(odd_SR),
        .even_RL(even_RL),
        .even_RR(even_RR),
        .odd_RL(odd_RL),
        .odd_RR(odd_RR),
        .odd_cmp_en(odd_cmp_en),
        .even_cmp_en(even_cmp_en)
    );

    wire [(DATA_NUM-1)*FIX_POINT_WIDTH-1:0] in_right1;
    wire [(DATA_NUM-1)*FIX_POINT_WIDTH-1:0] in_right2;
    wire [(DATA_NUM-1)*FIX_POINT_WIDTH-1:0] out_right1;
    wire [(DATA_NUM-1)*FIX_POINT_WIDTH-1:0] out_right2;
    wire [DATA_NUM*FIX_POINT_WIDTH-1:0] out;


    // 连线规律，但凡左边的端口，最低的那个元素的索引都得-2，右边的端口则是-1
    genvar i;
    generate  // 前提假设： PE为偶数个
        for (i = 1 ; i <= (DATA_NUM >> 1); i = i + 1) begin:sort_pe
            if (i & 1'b1 == 1) begin // odd
                if (i == 1) begin // 左边第一个PE
                    sort_pe #(
                        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
                        .DATA_NUM(DATA_NUM)
                    ) u_sort_pe (
                        .clk(clk),
                        .rst(rst),
                        .sort_en(odd_cmp_en),
                        .write_enable(write_enable), 
                        .send_left(odd_SL),
                        .send_right(odd_SR),
                        .receive_left(odd_RL),
                        .receive_right(odd_RR),
                        .write_data1(in[(2*i-1)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH]),
                        .write_data2(in[(2*i)*FIX_POINT_WIDTH-1:(2*i-1)*FIX_POINT_WIDTH]),

                        .in_right1(in_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .in_right2(in_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .out_right1(out_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .out_right2(out_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .in_left1(),
                        .in_left2(),

                        .out_left1(), // 不连接
                        .out_left2(), // 不连接
                        .out(out[(2*i)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH])
                    );
                end
                else begin
                    sort_pe  #(
                        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
                        .DATA_NUM(DATA_NUM)
                    ) u_sort_pe (
                        .clk(clk),
                        .rst(rst),
                        .sort_en(odd_cmp_en),
                        .write_enable(write_enable),
                        .send_left(odd_SL),
                        .send_right(odd_SR),
                        .receive_left(odd_RL),
                        .receive_right(odd_RR),
                        .write_data1(in[(2*i-1)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH]),
                        .write_data2(in[(2*i)*FIX_POINT_WIDTH-1:(2*i-1)*FIX_POINT_WIDTH]),

                        .in_right1(in_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .in_right2(in_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .out_right1(out_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .out_right2(out_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .in_left1(out_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .in_left2(out_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),

                        .out_left1(in_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out_left2(in_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out(out[(2*i)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH])
                    );
                end
            end
            else begin // even
                if (i == (DATA_NUM >> 1)) begin // 右边最后一个
                    sort_pe  #(
                        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
                        .DATA_NUM(DATA_NUM)
                    ) u_sort_pe (
                        .clk(clk),
                        .rst(rst),
                        .sort_en(even_cmp_en),
                        .write_enable(write_enable), 
                        .send_left(even_SL),
                        .send_right(even_SR),
                        .receive_left(even_RL),
                        .receive_right(even_RR),
                        .write_data1(in[(2*i-1)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH]),
                        .write_data2(in[(2*i)*FIX_POINT_WIDTH-1:(2*i-1)*FIX_POINT_WIDTH]),

                        .in_right1(),
                        .in_right2(),

                        .out_right1(), // 不连接
                        .out_right2(), // 不连接

                        .in_left1(out_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .in_left2(out_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),

                        .out_left1(in_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out_left2(in_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out(out[(2*i)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH])
                    );
                end
                else begin
                    sort_pe  #(
                        .FIX_POINT_WIDTH(FIX_POINT_WIDTH),
                        .DATA_NUM(DATA_NUM)
                    ) u_sort_pe (
                        .clk(clk),
                        .rst(rst),
                        .sort_en(even_cmp_en),
                        .write_enable(write_enable),   // 排序前存储待排序数据
                        .send_left(even_SL),
                        .send_right(even_SR),
                        .receive_left(even_RL),
                        .receive_right(even_RR),
                        .write_data1(in[(2*i-1)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH]),
                        .write_data2(in[(2*i)*FIX_POINT_WIDTH-1:(2*i-1)*FIX_POINT_WIDTH]),

                        .in_right1(in_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .in_right2(in_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .out_right1(out_right1[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),
                        .out_right2(out_right2[i*FIX_POINT_WIDTH-1:(i-1)*FIX_POINT_WIDTH]),

                        .in_left1(out_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .in_left2(out_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),

                        .out_left1(in_right1[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out_left2(in_right2[(i-1)*FIX_POINT_WIDTH-1:(i-2)*FIX_POINT_WIDTH]),
                        .out(out[(2*i)*FIX_POINT_WIDTH-1:(2*i-2)*FIX_POINT_WIDTH])
                    );
                end
            end
        end
    endgenerate
    
    assign max_out = out[DATA_NUM*FIX_POINT_WIDTH-1:(DATA_NUM-1)*FIX_POINT_WIDTH];
    // assign max_out = out[FIX_POINT_WIDTH-1:0];

endmodule

