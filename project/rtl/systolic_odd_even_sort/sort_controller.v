`timescale 1ns/1ns
module sort_controller# (
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 1 
) (
	input clk,
	input rst,
    input en,
    output reg write_enable,   // 排序前存储待排序数据
    output reg even_SL,
    output reg even_SR,
    output reg odd_SL,
    output reg odd_SR,
    
    output reg even_RL,
    output reg even_RR,
    output reg odd_RL,
    output reg odd_RR,
    output reg odd_cmp_en,
    output reg even_cmp_en,
    output reg sort_finish
);
    //one-hot
    parameter IDLE            =   7'b0000001; // 空闲且读入数据
    parameter EVEN_SL_ODD_RR  =   7'b0000010; // 偶数发左，奇数接右，2个周期
    parameter EVEN_RL_ODD_SR  =   7'b0000100; // 偶数收右，奇数发左，2个周期
    parameter EVEN_RR_ODD_SL  =   7'b0001000; // 偶数接右，奇数发左，2个周期
    parameter EVEN_SR_ODD_RL  =   7'b0010000; // 偶数发右，奇数接左，2个周期
    parameter EVEN_COMPARE    =   7'b0100000; // 奇数PE比较数据 6个周期
    parameter ODD_COMPARE     =   7'b1000000; // 偶数PE比较数据 6个周期
    localparam [10:0] SORT_ALL_NUM = (DATA_NUM / 2 - 1) * 9 + 1; // 64 136

    reg [6:0] current_state;
    reg [6:0] next_state;

    always @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else current_state <= next_state;
    end

    reg [3:0] cnt;
    always @(posedge clk) begin
        if (rst) cnt <= 0;
        else if (next_state == EVEN_COMPARE || next_state == ODD_COMPARE) cnt <= cnt + 1;
        else cnt <= 0;
    end

    // 
    reg cmp_finsih;
    always @(posedge clk) begin
        if (rst) cmp_finsih <= 0;
        else if (cnt == 6) cmp_finsih <= 1;
        else cmp_finsih <= 0;
    end

    reg [10:0] cnt_finish;
    assign sort_finish = (cnt_finish == SORT_ALL_NUM) ? 1 : 0;
    always @(posedge clk) begin
        if (rst) cnt_finish <= 0;
        else if (en && cnt_finish < SORT_ALL_NUM)cnt_finish <= cnt_finish + 1;
        else cnt_finish <= 0;
    end
    
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (en)             next_state = EVEN_SL_ODD_RR;
                else                next_state = IDLE;
            end
            EVEN_SL_ODD_RR:         next_state = ODD_COMPARE; //  偶数PE发送数据到左边 1个周期，然后奇数PE比较数据 6个周期
            ODD_COMPARE:begin
                if (cmp_finsih)     next_state = EVEN_RL_ODD_SR;
                else                next_state = ODD_COMPARE;
            end
            EVEN_RL_ODD_SR:         next_state = EVEN_RR_ODD_SL;
            EVEN_RR_ODD_SL:         next_state = EVEN_COMPARE;
            EVEN_COMPARE:begin
                if (cmp_finsih)     next_state = EVEN_SR_ODD_RL;
                else                next_state = EVEN_COMPARE;
            end
            EVEN_SR_ODD_RL:         next_state = EVEN_SL_ODD_RR;
            default: next_state = IDLE;
        endcase
    end

    // assign write_enable = (next_state == IDLE) ? 1 : 0;
    always @(posedge clk) begin
        if (rst) begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL <= 0;
            odd_SR <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL <= 0;
            odd_RR <= 0;

            odd_cmp_en <= 0;
            even_cmp_en <= 0;
            write_enable <= 1;
        end
        else if (next_state == EVEN_SL_ODD_RR) begin
            even_SL <= 1;
            even_SR <= 0;
            odd_SL <= 0;
            odd_SR <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL <= 0;
            odd_RR <= 1;

            odd_cmp_en <= 0;
            even_cmp_en <= 0;
            write_enable <= 0;
        end
        else if (next_state == ODD_COMPARE) begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL <= 0;
            odd_SR <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL <= 0;
            odd_RR <= 0;

            odd_cmp_en <= 1;
            even_cmp_en <= 0;
            write_enable <= 0;
        end
        else if (next_state == EVEN_RL_ODD_SR) begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL <= 0;
            odd_SR <= 1;

            even_RL <= 1;
            even_RR <= 0;
            odd_RL <= 0;
            odd_RR <= 0;

            odd_cmp_en <= 0;
            even_cmp_en <= 0;
            write_enable <= 0;
        end
        else if (next_state == EVEN_RR_ODD_SL) begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL  <= 1;
            odd_SR  <= 0;

            even_RL <= 0;
            even_RR <= 1;
            odd_RL  <= 0;
            odd_RR  <= 0;

            odd_cmp_en <= 0;
            even_cmp_en <= 0;
            write_enable <= 0;
        end
        else if (next_state == EVEN_COMPARE) begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL  <= 0;
            odd_SR  <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL  <= 0;
            odd_RR  <= 0;

            odd_cmp_en <= 0;
            even_cmp_en <= 1;
            write_enable <= 0;
        end
        else if (next_state == EVEN_SR_ODD_RL) begin
            even_SL <= 0;
            even_SR <= 1;
            odd_SL  <= 0;
            odd_SR  <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL  <= 1;
            odd_RR  <= 0;

            odd_cmp_en   <= 0;
            even_cmp_en  <= 0;
            write_enable <= 0;
        end
        else begin
            even_SL <= 0;
            even_SR <= 0;
            odd_SL  <= 0;
            odd_SR  <= 0;

            even_RL <= 0;
            even_RR <= 0;
            odd_RL  <= 0;
            odd_RR  <= 0;

            odd_cmp_en   <= 0;
            even_cmp_en  <= 0;
            write_enable <= 1;
        end
    end
 

endmodule

