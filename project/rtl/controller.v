module controller #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16,
    parameter DATA_NUM = 16
)  (
    input clk,
    input rst,
    input en,
    input [1:0] mode, // 00: softmax, 01: gelu, 10:silu, 11:root

    output reg max_en,
    output reg [2:0] s_in,
    output reg s_mux,
    output reg [2:0] s_mult,
    output reg s_add,
    output reg en_add,
    output reg en_mult,
    output reg valid,
    output reg finish
);

    parameter IDLE = 5'b00001;
    parameter MAX = 5'b00010;
    parameter FIRST_STAGE = 5'b00100;
    parameter SECOND_STAGE = 5'b01000;
    parameter FINISH = 5'b10000;
    parameter SORT_FINISH = (DATA_NUM / 2 - 1) * 9 + 1; 

    reg [10:0] cnt_sort;
    reg [2:0] cnt_stage1;
    reg [2:0] cnt_stage2;

    reg [4:0] current_state;
    reg [4:0] next_state;
    always @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (en)  begin
                    if (mode == 'b00) next_state = MAX;
                    else next_state = FIRST_STAGE;
                end           
                else     next_state = IDLE;
            end
            MAX:  begin
                if (cnt_sort == SORT_FINISH) next_state = FIRST_STAGE; 
                else next_state = MAX;
            end
            FIRST_STAGE: begin
                if (cnt_stage1 == 'd4) begin
                    if (mode == 'b11) next_state = FINISH; // root只有一个阶段
                    else next_state = SECOND_STAGE;
                end
                else next_state = FIRST_STAGE; 
            end
            SECOND_STAGE:  begin
                if (cnt_stage2 == 'd4) next_state = FINISH;
                else next_state = SECOND_STAGE;
            end 
            FINISH :begin 
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            max_en <= 0;
            s_in <= 0;
            s_mux <= 0;
            s_mult <= 0;
            s_add <= 0;
            en_add <= 0;
            en_mult <= 0;
            cnt_sort <= 0;
            cnt_stage1 <= 0;
            cnt_stage2 <= 0;
            finish <= 0;
            valid <= 0;
        end
        else if (next_state == MAX) begin
            max_en <= 1;
            s_in <= 0;
            s_mux <= 0;
            s_mult <= 0;
            s_add <= 0;
            en_add <= 0;
            en_mult <= 0;
            cnt_sort <= cnt_sort + 1;
            cnt_stage1 <= 0;
            cnt_stage2 <= 0;
            finish <= 0;
            valid <= 0;
        end
        else if (next_state == FIRST_STAGE) begin
            if (mode == 'b00) begin  // softmax 1轮
                max_en <= 0;
                s_in <= 0;
                valid <= 0;
                s_mux <= 1;
                s_mult <= 2;
                s_add <= 1;
                en_mult <= 1;
                en_add <= 0;
                cnt_sort <= 0;
                cnt_stage1 <= cnt_stage1 + 1;
                cnt_stage2 <= 0;
                finish <= 0;
            end
            else if (mode == 'b01 || mode == 'b10) begin  // gelu/silu 1轮
                max_en <= 0;
                s_in = 2;
                valid = 0;
                s_mux = 1;
                s_mult = 3;
                s_add = 0; 
                en_mult = 1;
                en_add = 0;
                cnt_sort <= 0;
                cnt_stage1 <= cnt_stage1 + 1;
                cnt_stage2 <= 0;
                finish <= 0;
            end
            else begin // root 1轮
                max_en <= 0;
                valid = 0;
                s_in <= 4;
                s_mux = 0;
                s_mult = 1;
                s_add = 0; 
                en_mult = 1;
                en_add = 0;
                cnt_sort <= 0;
                cnt_stage1 <= cnt_stage1 + 1;
                cnt_stage2 <= 0;
                finish <= 0;
            end
        end
        else if (next_state == SECOND_STAGE) begin
            if (mode == 'b00) begin // softmax 2轮
                max_en <= 0;
                s_in = 1;
                s_mux = 0;
                s_mult = 0;
                s_add = 1; // softmax 2轮，add不管
                en_mult = 1;
                en_add = 1; // ru4的结果是0008
                cnt_sort <= 0;
                cnt_stage1 <= 0;
                cnt_stage2 <= cnt_stage2 + 1;
                finish <= 0;
                valid <= 1;
            end
            else begin  // gelu/silu 2轮
                max_en <= 0;
                s_in = 3;
                s_mux = 0;
                s_mult = 0;
                s_add = 1; // gelu/silu 2轮，add不管
                en_mult = 0;
                en_add = 1;
                cnt_sort <= 0;
                cnt_stage1 <= 0;
                cnt_stage2 <= cnt_stage2 + 1;
                finish <= 0;
                valid <= 1;
            end
        end
        else if (next_state == FINISH) begin
            max_en <= 0;
            s_in <= 0;
            s_mux <= 0;
            s_mult <= 0;
            s_add <= 0;
            en_add <= 0;
            en_mult <= 0;
            cnt_sort <= 0;
            cnt_sort <= 0;
            cnt_stage1 <= 0;
            cnt_stage2 <= 0;
            finish <= 1;
            valid <= 0;
        end
        else begin
            max_en <= 0;
            s_in <= 0;
            s_mux <= 0;
            s_mult <= 0;
            s_add <= 0;
            en_add <= 0;
            en_mult <= 0;
            cnt_sort <= 0;
            cnt_sort <= 0;
            cnt_stage1 <= 0;
            cnt_stage2 <= 0;
            finish <= 0;
            valid <= 0;
        end
    end

endmodule

