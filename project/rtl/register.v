`timescale 1ns/1ns
module register#(
    parameter DATASIZE = 2
) (
    input clk,
    input rst,
    input [DATASIZE-1:0] d,
    output [DATASIZE-1:0] q
);

    reg [DATASIZE-1:0] regfile;
    always @(posedge clk) begin
        if (rst) regfile <= 0;
        else regfile <= d;
    end

    assign q = regfile;


endmodule

