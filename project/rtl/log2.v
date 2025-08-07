module log2 #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)  (
    input  [FIX_POINT_WIDTH - 1:0] in,
    output [FIX_POINT_WIDTH - 1:0] out
);

    reg [FIX_POINT_WIDTH - 1:0] one_hot;
    reg [4:0] position;

    integer i;
    always @(*) begin
        position = 0; // 默认位置为0
        one_hot = 0;
        // 2. 从最高位(MSB)开始向下扫描
        for (i = FIX_POINT_WIDTH - 1; i >= 0; i = i - 1) begin
            if (in[i] == 1'b1) begin
                // 3. 一旦找到第一个'1'
                position = i + 1;         // 记录当前位置
                one_hot = 1 << i;
                break;                // 立即退出循环，因为我们只关心最高位的'1'
            end
        end
    end

    wire [FIX_POINT_WIDTH - 1:0] m_sub_one; // m - 1
    wire less_1;
    wire [3:0] shift_len;
    wire [FIX_POINT_WIDTH - 1:0] shift;

    assign m_sub_one = in & (~one_hot);//m-1
    assign less_1 = (position <= Bf) ? 1 : 0;
    assign shift_len = (less_1) ? Bf - position + 1 : position - Bf - 1;
    assign shift = (less_1) ? m_sub_one << shift_len : m_sub_one >> shift_len;
    assign out = ((position - Bf - 1) << Bf) + shift;
endmodule