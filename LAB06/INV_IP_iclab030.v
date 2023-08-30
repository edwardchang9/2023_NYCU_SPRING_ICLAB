//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2;
output [IP_WIDTH-1:0] OUT_INV;
parameter WIDTH = IP_WIDTH + (IP_WIDTH/2) + (IP_WIDTH%2);

genvar i;
generate
if(IP_WIDTH != 6) begin

	wire [IP_WIDTH-1:0] a [WIDTH:0];
	wire [IP_WIDTH-1:0] b [WIDTH:0];
	wire signed [IP_WIDTH-1:0] s [WIDTH:0];
	wire signed [IP_WIDTH-1:0] t [WIDTH:0];

	assign a[0] = (IN_1 > IN_2) ? {1'b0,IN_2} : {1'b0,IN_1};
	assign b[0] = (IN_1 > IN_2) ? {1'b0,IN_1} : {1'b0,IN_2};

	wire signed [IP_WIDTH:0] add_result;
	assign add_result = s[0] + b[0];
	assign OUT_INV = (s[0] > 0) ? s[0][IP_WIDTH-1:0] : add_result[IP_WIDTH-1:0];
	assign s[WIDTH] = 0;
	assign t[WIDTH] = 0;
	for (i=0;i<WIDTH;i=i+1) begin
		// next a and b
		assign a[i+1] = b[i];
		assign b[i+1] = a[i] % b[i];
		
		assign s[i] = (b[i] == 0) ? a[i] : t[i+1];
		assign t[i] = (b[i] == 0) ? 0 : s[i+1] - ((a[i] / b[i]) * t[i+1]);
	end
end
else begin: else_loop
	for (i=0;i<8;i=i+1) begin: gen_loop
		// a and b
		if(i == 0) begin:if_0
			wire [5:0] a;
			wire [5:0] b;
			assign a = (IN_1 > IN_2) ? IN_2 : IN_1;
			assign b = (IN_1 > IN_2) ? IN_1 : IN_2;
		end
		else if(i == 1) begin: if_1
			wire [5:0] a;
			wire [5:0] b;
			assign a = else_loop.gen_loop[0].if_0.b;
			assign b = else_loop.gen_loop[0].if_0.a % else_loop.gen_loop[0].if_0.b;
			wire signed [5:0] s;
			wire signed [5:0] t;
			assign s = (b == 1) ? 0 : else_loop.gen_loop[2].if_2.t;
			assign t = (b == 1) ? 1 : {else_loop.gen_loop[2].if_2.s[4],else_loop.gen_loop[2].if_2.s} - ((a / b) * else_loop.gen_loop[2].if_2.t);
		end
		else if(i == 2) begin: if_2
			wire [5:0] a;
			wire [4:0] b;
			assign a = else_loop.gen_loop[1].if_1.b;
			assign b = else_loop.gen_loop[1].if_1.a % else_loop.gen_loop[1].if_1.b;
			wire signed [4:0] s;
			wire signed [5:0] t;
			assign s = (b == 1) ? 0 : else_loop.gen_loop[3].if_3.t;
			assign t = (b == 1) ? 1 : {else_loop.gen_loop[3].if_3.s[4],else_loop.gen_loop[3].if_3.s} - ((a / b) * {else_loop.gen_loop[3].if_3.t[4],else_loop.gen_loop[3].if_3.t});
		end
		else if(i == 3) begin: if_3
			wire [4:0] a;
			wire [4:0] b;
			assign a = else_loop.gen_loop[2].if_2.b;
			assign b = else_loop.gen_loop[2].if_2.a % else_loop.gen_loop[2].if_2.b;
			wire signed [4:0] s;
			wire signed [4:0] t;
			assign s = (b == 1) ? 0 : else_loop.gen_loop[4].if_4.t;
			assign t = (b == 1) ? 1 : {else_loop.gen_loop[4].if_4.s[3],else_loop.gen_loop[4].if_4.s} - ((a / b) * else_loop.gen_loop[4].if_4.t);
		end
		else if(i == 4) begin: if_4
			wire [4:0] a;
			wire [3:0] b;
			assign a = else_loop.gen_loop[3].if_3.b;
			assign b = else_loop.gen_loop[3].if_3.a % else_loop.gen_loop[3].if_3.b;
			wire signed [3:0] s;
			wire signed [4:0] t;
			assign s = (b == 1) ? 0 : else_loop.gen_loop[5].if_5.t;
			assign t = (b == 1) ? 1 : {{2{else_loop.gen_loop[5].if_5.s[2]}},else_loop.gen_loop[5].if_5.s} - ((a / b) * {else_loop.gen_loop[5].if_5.t[3],else_loop.gen_loop[5].if_5.t});
		end
		else if(i == 5) begin: if_5
			wire [3:0] a;
			wire [2:0] b;
			assign a = else_loop.gen_loop[4].if_4.b;
			assign b = else_loop.gen_loop[4].if_4.a % else_loop.gen_loop[4].if_4.b;
			wire signed [2:0] s;
			wire signed [3:0] t;
			assign s = (b == 1) ? 0 : {else_loop.gen_loop[6].if_6.t[1], else_loop.gen_loop[6].if_6.t};
			assign t = (b == 1) ? 1 : else_loop.gen_loop[6].if_6.s - ((a / b) * {{2{else_loop.gen_loop[6].if_6.t[1]}},else_loop.gen_loop[6].if_6.t});
		end
		else if(i == 6) begin: if_6
			wire [2:0] a;
			wire [1:0] b;
			assign a = else_loop.gen_loop[5].if_5.b;
			assign b = else_loop.gen_loop[5].if_5.a % else_loop.gen_loop[5].if_5.b;
			wire s;
			wire signed [1:0] t;
			assign s = (b == 1) ? 0 : 1;
			assign t = (b == 1) ? 1 : 2'b11;
		end
	end
	assign OUT_INV = (else_loop.gen_loop[1].if_1.t > 0) ? else_loop.gen_loop[1].if_1.t : else_loop.gen_loop[1].if_1.t + else_loop.gen_loop[0].if_0.b;
end
endgenerate

endmodule