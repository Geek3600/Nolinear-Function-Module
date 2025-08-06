module add #(
    parameter Bf = 8,
    parameter FIX_POINT_WIDTH = 16
)  (
    input [FIX_POINT_WIDTH - 1:0] in0,
    input [FIX_POINT_WIDTH - 1:0] in1,
    input [FIX_POINT_WIDTH - 1:0] u,
    input s_add,
    output [FIX_POINT_WIDTH - 1:0] out0,
    output [FIX_POINT_WIDTH - 1:0] out1
);

    wire [FIX_POINT_WIDTH - 1:0]  mux;
    assign mux = (s_add) ? in1 : (16'b1 << u);
    assign out0 = in0 + mux;
    assign out1 = out0;
endmodule