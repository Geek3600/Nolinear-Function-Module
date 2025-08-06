module tb_systolic_odd_even_sort();
	parameter CLOCK_PERIOD = 10;
	reg clk;
	reg rst;

	//===========生成时钟和复位信号===============
	always #(CLOCK_PERIOD/2) clk = ~clk;
	initial begin
		clk = 0;
		rst = 1;
		#CLOCK_PERIOD;
		rst = 0;
	end
	//===========生成时钟和复位信号===============

	//=================测试行为===================
    reg en;
    reg  [4*16-1:0] in;
    wire [15:0] max_out;


	initial begin
		#CLOCK_PERIOD;
		en = 1;
		in = 'h0005000800010004;
		#CLOCK_PERIOD;
	end
	systolic_odd_even_sort # (
		.FIX_POINT_WIDTH(16),
    	.DATA_NUM(4) 
	) u_systolic_odd_even_sort(
		.clk(clk),
		.rst(rst),
		.en(en),
		.in(in),
		.max_out(max_out) 
	);
 
    //=================测试行为===================
	
	//================生成波形====================
	initial begin
		$fsdbDumpfile("tb_systolic_odd_even_sort.fsdb");
		$fsdbDumpvars("+all");
	end
    //================生成波形====================
	initial begin
		#1000;
		// if (max_out == mem_res[0][16-1:0]) $display("pass");
		$display("%d",max_out);
		$finish;
	end
endmodule
