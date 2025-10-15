`timescale 1ns/1ns

// 4个数排序，第6个时钟输出排序结果，第7个周期可读到s
module sort4 # (
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 1 
) (
    input clk,
    input rst,
    input sort_en,
    output  sort_finish,
    input [FIX_POINT_WIDTH-1:0] in1,
    input [FIX_POINT_WIDTH-1:0] in2,
    input [FIX_POINT_WIDTH-1:0] in3,
    input [FIX_POINT_WIDTH-1:0] in4,
    output  [FIX_POINT_WIDTH-1:0] out_small1,
    output  [FIX_POINT_WIDTH-1:0] out_small2,
    output  [FIX_POINT_WIDTH-1:0] out_large1,
    output  [FIX_POINT_WIDTH-1:0] out_large2
);

    reg  [2:0] cnt;
    reg  [FIX_POINT_WIDTH-1:0] num1;
    reg  [FIX_POINT_WIDTH-1:0] num2;
    reg  [FIX_POINT_WIDTH-1:0] num3;
    reg  [FIX_POINT_WIDTH-1:0] num4;

    always @(posedge clk) begin
        if (rst) cnt <= 0;
        else if (sort_en && cnt < 'd6) cnt <= cnt + 1;
        else cnt <= 0;
    end
    
    assign sort_finish = (cnt == 6) ? 1 : 0;
    always @(posedge clk) begin
        if (rst) begin
            num1 <= 0;
            num2 <= 0;
            num3 <= 0;
            num4 <= 0;
            // sort_finish <= 0;
        end
        else if (sort_en && cnt == 0) begin
            num1 <= in1;
            num2 <= in2;
            num3 <= in3;
            num4 <= in4;
            // sort_finish <= 0;
        end
        else if (cnt == 1) begin
            if (num1 > num2) begin
                num1 <= num2;
                num2 <= num1;
                num3 <= num3;
                num4 <= num4; 
                // sort_finish <= 0;
            end
            else begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;
            end
        end
        else if (cnt == 2) begin
            if (num3 > num4) begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num4;
                num4 <= num3;
                // sort_finish <= 0;
            end
            else begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;
            end
        end
        else if (cnt == 3) begin
            if (num2 > num3) begin
                num1 <= num1;
                num2 <= num3;
                num3 <= num2;
                num4 <= num4;
                // sort_finish <= 0;
            end
            else begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;
            end
        end
        else if (cnt == 4) begin
            if (num3 > num4) begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num4;
                num4 <= num3;
                // sort_finish <= 0;
            end
            else begin  
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;
            end
        end
        else if (cnt == 5) begin
            if (num1 > num2) begin
                num1 <= num2;
                num2 <= num1;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;   
            end
            else begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 0;
            end
        end
        else if (cnt == 6) begin
            if (num2 > num3) begin
                num1 <= num1;
                num2 <= num3;
                num3 <= num2;
                num4 <= num4;
                // sort_finish <= 1;
            end
            else begin
                num1 <= num1;
                num2 <= num2;
                num3 <= num3;
                num4 <= num4;
                // sort_finish <= 1;
            end
        end
        else begin
            num1 <= num1;
            num2 <= num2;
            num3 <= num3;
            num4 <= num4;
            // sort_finish <= 0;
        end
    end

    assign out_small1 = num1;
    assign out_small2 = num2;
    assign out_large1 = num3;
    assign out_large2 = num4;


endmodule

