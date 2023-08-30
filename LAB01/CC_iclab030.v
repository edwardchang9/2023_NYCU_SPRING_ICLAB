module CC(
  in_s0,
  in_s1,
  in_s2,
  in_s3,
  in_s4,
  in_s5,
  in_s6,
  opt,
  a,
  b,
  s_id0,
  s_id1,
  s_id2,
  s_id3,
  s_id4,
  s_id5,
  s_id6,
  out

);
input [3:0]in_s0;
input [3:0]in_s1;
input [3:0]in_s2;
input [3:0]in_s3;
input [3:0]in_s4;
input [3:0]in_s5;
input [3:0]in_s6;
input [2:0]opt;
input [1:0]a;
input [2:0]b;
output [2:0] s_id0;
output [2:0] s_id1;
output [2:0] s_id2;
output [2:0] s_id3;
output [2:0] s_id4;
output [2:0] s_id5;
output [2:0] s_id6;
output [2:0] out; 
//==================================================================
// reg & wire
//==================================================================


//==================================================================
// design
//==================================================================

// sort
wire w_s0, w_s1, w_s2, w_s3, w_s4, w_s5, w_s6;

wire [3:0]after_sort_s0;
wire [3:0]after_sort_s1;
wire [3:0]after_sort_s2;
wire [3:0]after_sort_s3;
wire [3:0]after_sort_s4;
wire [3:0]after_sort_s5;
wire [3:0]after_sort_s6;
// bar when negative
xor x0(w_s0, opt[0], in_s0[3]);
xor x1(w_s1, opt[0], in_s1[3]);
xor x2(w_s2, opt[0], in_s2[3]);
xor x3(w_s3, opt[0], in_s3[3]);
xor x4(w_s4, opt[0], in_s4[3]);
xor x5(w_s5, opt[0], in_s5[3]);
xor x6(w_s6, opt[0], in_s6[3]);
// get back
wire w1_s0, w1_s1, w1_s2, w1_s3, w1_s4, w1_s5, w1_s6;
xor x10(after_sort_s0[3], w1_s0, opt[0]);
xor x11(after_sort_s1[3], w1_s1, opt[0]);
xor x12(after_sort_s2[3], w1_s2, opt[0]);
xor x13(after_sort_s3[3], w1_s3, opt[0]);
xor x14(after_sort_s4[3], w1_s4, opt[0]);
xor x15(after_sort_s5[3], w1_s5, opt[0]);
xor x16(after_sort_s6[3], w1_s6, opt[0]);
// sort
sort sorter1(
	.opt(opt[1]),
	.in_s0({w_s0, in_s0[2:0]}),
	.in_s1({w_s1, in_s1[2:0]}),
	.in_s2({w_s2, in_s2[2:0]}),
	.in_s3({w_s3, in_s3[2:0]}),
	.in_s4({w_s4, in_s4[2:0]}),
	.in_s5({w_s5, in_s5[2:0]}),
	.in_s6({w_s6, in_s6[2:0]}),
	/*
	.out_s0(after_sort_s0),
	.out_s1(after_sort_s1),
	.out_s2(after_sort_s2),
	.out_s3(after_sort_s3),
	.out_s4(after_sort_s4),
	.out_s5(after_sort_s5),
	.out_s6(after_sort_s6),
	*/
	// add back
	.out_s0({w1_s0, after_sort_s0[2:0]}),
	.out_s1({w1_s1, after_sort_s1[2:0]}),
	.out_s2({w1_s2, after_sort_s2[2:0]}),
	.out_s3({w1_s3, after_sort_s3[2:0]}),
	.out_s4({w1_s4, after_sort_s4[2:0]}),
	.out_s5({w1_s5, after_sort_s5[2:0]}),
	.out_s6({w1_s6, after_sort_s6[2:0]}),
	
	.out_id0(s_id0),
	.out_id1(s_id1),
	.out_id2(s_id2),
	.out_id3(s_id3),
	.out_id4(s_id4),
	.out_id5(s_id5),
	.out_id6(s_id6)
);
wire [3:0] calculate_in_s0;
wire [3:0] calculate_in_s1;
wire [3:0] calculate_in_s2;
wire [3:0] calculate_in_s4;
wire [3:0] calculate_in_s5;
wire [3:0] calculate_in_s6;

// sort back from largest to smallest
assign calculate_in_s0 = (opt[1]) ? after_sort_s0 : after_sort_s6;
assign calculate_in_s1 = (opt[1]) ? after_sort_s1 : after_sort_s5;
assign calculate_in_s2 = (opt[1]) ? after_sort_s2 : after_sort_s4;
assign calculate_in_s4 = (opt[1]) ? after_sort_s4 : after_sort_s2;
assign calculate_in_s5 = (opt[1]) ? after_sort_s5 : after_sort_s1;
assign calculate_in_s6 = (opt[1]) ? after_sort_s6 : after_sort_s0;


//extend s

wire extend_s0, extend_s1, extend_s2, extend_s3, extend_s4, extend_s5, extend_s6;
and a0(extend_s0, calculate_in_s0[3], opt[0]);
and a1(extend_s1, calculate_in_s1[3], opt[0]);
and a2(extend_s2, calculate_in_s2[3], opt[0]);
and a3(extend_s3, after_sort_s3[3], opt[0]);
and a4(extend_s4, calculate_in_s4[3], opt[0]);
and a5(extend_s5, calculate_in_s5[3], opt[0]);
and a6(extend_s6, calculate_in_s6[3], opt[0]);


// calculate mean
wire signed [3:0] mean;

mean_calculator mean_calculator1(
	.opt(opt[0]),
	.in_s0({{3{extend_s0}}, calculate_in_s0}),
	.in_s1({{3{extend_s1}}, calculate_in_s1}),
	.in_s2({{3{extend_s2}}, calculate_in_s2}),
	.in_s3({{3{extend_s3}}, after_sort_s3}),
	.in_s4({{3{extend_s4}}, calculate_in_s4}),
	.in_s5({{3{extend_s5}}, calculate_in_s5}),
	.in_s6({{3{extend_s6}}, calculate_in_s6}),
	.mean(mean)
);


// judge
wire [2:0] judge_result;

judge_network jn1(
	.in_s0(calculate_in_s0),
	.in_s1(calculate_in_s1),
	.in_s2(calculate_in_s2),
	.in_s3(after_sort_s3),
	.in_s4(calculate_in_s4),
	.in_s5(calculate_in_s5),
	.in_s6(calculate_in_s6),
	.opt(opt[0]),
	.mean(mean),
	.a(a),
	.b(b),
	.out(judge_result)
);


// output
wire out0, out1, out2;
xor xor_out0(out0, judge_result[0], opt[2]);
xor xor_out1(out1, judge_result[1], opt[2]);
xor xor_out2(out2, judge_result[2], opt[2]);

assign out = {out2, out1, out0};

endmodule

// sort
module swap(
	input trigger,
	input [3:0] in1,
	input [3:0] in2,
	input [2:0] id1,
	input [2:0] id2,
	output [3:0] out1,
	output [3:0] out2,
	output [2:0] out_id1,
	output [2:0] out_id2
);
assign out1 = (trigger) ? in2 : in1;
assign out2 = (trigger) ? in1 : in2;
assign out_id1 = (trigger) ? id2 : id1;
assign out_id2 = (trigger) ? id1 : id2;
endmodule

// if opt = 0, 1 is small

module comp(
	input opt,
	input [3:0] in1,
	input [3:0] in2,
	input [2:0] id1,
	input [2:0] id2,
	output reg [3:0] out1,
	output reg [3:0] out2,
	output reg [2:0] out_id1,
	output reg [2:0] out_id2
);
always@* begin
	if (opt) begin
		if(in1 >= in2) begin
			out1 = in1;
			out2 = in2;
			out_id1 = id1;
			out_id2 = id2;
		end
		else begin
			out1 = in2;
			out2 = in1;
			out_id1 = id2;
			out_id2 = id1;
		end
	end
	else begin
		if(in1 <= in2) begin
			out1 = in1;
			out2 = in2;
			out_id1 = id1;
			out_id2 = id2;
		end
		else begin
			out1 = in2;
			out2 = in1;
			out_id1 = id2;
			out_id2 = id1;
		end
	end
end

endmodule

module comp_with_id(
	input opt,
	input [3:0] in1,
	input [3:0] in2,
	input [2:0] id1,
	input [2:0] id2,
	output [3:0] out1,
	output [3:0] out2,
	output [2:0] out_id1,
	output [2:0] out_id2
);
wire bigger, equal, id_bigger;
wire out_trigger;
reg trigger;

swap s1(.trigger(out_trigger), .in1(in1), .in2(in2), .id1(id1), .id2(id2), .out1(out1),.out2(out2), .out_id1(out_id1), .out_id2(out_id2));

assign bigger = in1 > in2;
assign id_bigger = id1 > id2;
assign equal = in1 == in2;
assign out_trigger = trigger;
always@* begin
	case({equal, id_bigger, opt, bigger})
	4'b0000: trigger = 0;
	4'b0001: trigger = 1;
	4'b0010: trigger = 1;
	4'b0011: trigger = 0;
	4'b0100: trigger = 0;
	4'b0101: trigger = 1;
	4'b0110: trigger = 1;
	4'b0111: trigger = 0;
	4'b1100: trigger = 1;
	4'b1101: trigger = 1;
	4'b1110: trigger = 1;
	4'b1111: trigger = 1;
	default: trigger = 0;
	endcase
end

endmodule

module sort(
	input opt,
	input [3:0] in_s0,
	input [3:0] in_s1,
	input [3:0] in_s2,
	input [3:0] in_s3,
	input [3:0] in_s4,
	input [3:0] in_s5,
	input [3:0] in_s6,
	output [3:0] out_s0,
	output [3:0] out_s1,
	output [3:0] out_s2,
	output [3:0] out_s3,
	output [3:0] out_s4,
	output [3:0] out_s5,
	output [3:0] out_s6,
	output [2:0] out_id0,
	output [2:0] out_id1,
	output [2:0] out_id2,
	output [2:0] out_id3,
	output [2:0] out_id4,
	output [2:0] out_id5,
	output [2:0] out_id6
);
wire [2:0] id_s0;
wire [2:0] id_s1;
wire [2:0] id_s2;
wire [2:0] id_s3;
wire [2:0] id_s4;
wire [2:0] id_s5;
wire [2:0] id_s6;

assign id_s0 = 3'b000;
assign id_s1 = 3'b001;
assign id_s2 = 3'b010;
assign id_s3 = 3'b011;
assign id_s4 = 3'b100;
assign id_s5 = 3'b101;
assign id_s6 = 3'b110;

wire [3:0] temp1_s0;
wire [2:0] temp1_id0;
wire [3:0] temp2_s0;
wire [2:0] temp2_id0;
wire [3:0] temp3_s0;
wire [2:0] temp3_id0;
assign out_s0 = temp3_s0;
assign out_id0 = temp3_id0;

wire [3:0] temp1_s1;
wire [2:0] temp1_id1;
wire [3:0] temp2_s1;
wire [2:0] temp2_id1;
wire [3:0] temp3_s1;
wire [2:0] temp3_id1;
wire [3:0] temp4_s1;
wire [2:0] temp4_id1;
wire [3:0] temp5_s1;
wire [2:0] temp5_id1;
assign out_s1 = temp5_s1;
assign out_id1 = temp5_id1;

wire [3:0] temp1_s2;
wire [2:0] temp1_id2;
wire [3:0] temp2_s2;
wire [2:0] temp2_id2;
wire [3:0] temp3_s2;
wire [2:0] temp3_id2;
wire [3:0] temp4_s2;
wire [2:0] temp4_id2;
wire [3:0] temp5_s2;
wire [2:0] temp5_id2;
assign out_s2 = temp5_s2;
assign out_id2 = temp5_id2;

wire [3:0] temp1_s3;
wire [2:0] temp1_id3;
wire [3:0] temp2_s3;
wire [2:0] temp2_id3;
wire [3:0] temp3_s3;
wire [2:0] temp3_id3;
wire [3:0] temp4_s3;
wire [2:0] temp4_id3;
wire [3:0] temp5_s3;
wire [2:0] temp5_id3;
assign out_s3 = temp5_s3;
assign out_id3 = temp5_id3;

wire [3:0] temp1_s4;
wire [2:0] temp1_id4;
wire [3:0] temp2_s4;
wire [2:0] temp2_id4;
wire [3:0] temp3_s4;
wire [2:0] temp3_id4;
wire [3:0] temp4_s4;
wire [2:0] temp4_id4;
wire [3:0] temp5_s4;
wire [2:0] temp5_id4;
wire [3:0] temp6_s4;
wire [2:0] temp6_id4;
assign out_s4 = temp6_s4;
assign out_id4 = temp6_id4;

wire [3:0] temp1_s5;
wire [2:0] temp1_id5;
wire [3:0] temp2_s5;
wire [2:0] temp2_id5;
wire [3:0] temp3_s5;
wire [2:0] temp3_id5;
wire [3:0] temp4_s5;
wire [2:0] temp4_id5;
assign out_s5 = temp4_s5;
assign out_id5 = temp4_id5;

wire [3:0] temp1_s6;
wire [2:0] temp1_id6;
wire [3:0] temp2_s6;
wire [2:0] temp2_id6;
wire [3:0] temp3_s6;
wire [2:0] temp3_id6;
wire [3:0] temp4_s6;
wire [2:0] temp4_id6;
assign out_s6 = temp4_s6;
assign out_id6 = temp4_id6;

comp c1(.opt(opt), .in1(in_s0), .in2(in_s1), .id1(id_s0), .id2(id_s1), .out1(temp1_s0), .out2(temp1_s1), .out_id1(temp1_id0), .out_id2(temp1_id1));
comp c2(.opt(opt), .in1(in_s2), .in2(in_s3), .id1(id_s2), .id2(id_s3), .out1(temp1_s2), .out2(temp1_s3), .out_id1(temp1_id2), .out_id2(temp1_id3));
comp c3(.opt(opt), .in1(in_s4), .in2(in_s5), .id1(id_s4), .id2(id_s5), .out1(temp1_s4), .out2(temp1_s5), .out_id1(temp1_id4), .out_id2(temp1_id5));
comp c4(.opt(opt), .in1(temp1_s0), .in2(temp1_s2), .id1(temp1_id0), .id2(temp1_id2), .out1(temp2_s0), .out2(temp2_s2), .out_id1(temp2_id0), .out_id2(temp2_id2));
comp c5(.opt(opt), .in1(temp1_s1), .in2(temp1_s3), .id1(temp1_id1), .id2(temp1_id3), .out1(temp2_s1), .out2(temp2_s3), .out_id1(temp2_id1), .out_id2(temp2_id3));
comp c6(.opt(opt), .in1(temp1_s4), .in2(in_s6), .id1(temp1_id4), .id2(id_s6), .out1(temp2_s4), .out2(temp1_s6), .out_id1(temp2_id4), .out_id2(temp1_id6));
comp c7(.opt(opt), .in1(temp2_s0), .in2(temp2_s4), .id1(temp2_id0), .id2(temp2_id4), .out1(temp3_s0), .out2(temp3_s4), .out_id1(temp3_id0), .out_id2(temp3_id4));
comp c8(.opt(opt), .in1(temp2_s1), .in2(temp1_s5), .id1(temp2_id1), .id2(temp1_id5), .out1(temp3_s1), .out2(temp2_s5), .out_id1(temp3_id1), .out_id2(temp2_id5));
comp c9(.opt(opt), .in1(temp2_s2), .in2(temp1_s6), .id1(temp2_id2), .id2(temp1_id6), .out1(temp3_s2), .out2(temp2_s6), .out_id1(temp3_id2), .out_id2(temp2_id6));
comp_with_id c10(.opt(opt), .in1(temp3_s1), .in2(temp3_s4), .id1(temp3_id1), .id2(temp3_id4), .out1(temp4_s1), .out2(temp4_s4), .out_id1(temp4_id1), .out_id2(temp4_id4));
comp_with_id c11(.opt(opt), .in1(temp2_s3), .in2(temp2_s6), .id1(temp2_id3), .id2(temp2_id6), .out1(temp3_s3), .out2(temp3_s6), .out_id1(temp3_id3), .out_id2(temp3_id6));
comp_with_id c12(.opt(opt), .in1(temp3_s2), .in2(temp4_s4), .id1(temp3_id2), .id2(temp4_id4), .out1(temp4_s2), .out2(temp5_s4), .out_id1(temp4_id2), .out_id2(temp5_id4));
comp_with_id c13(.opt(opt), .in1(temp3_s3), .in2(temp2_s5), .id1(temp3_id3), .id2(temp2_id5), .out1(temp4_s3), .out2(temp3_s5), .out_id1(temp4_id3), .out_id2(temp3_id5));
comp_with_id c14(.opt(opt), .in1(temp4_s1), .in2(temp4_s2), .id1(temp4_id1), .id2(temp4_id2), .out1(temp5_s1), .out2(temp5_s2), .out_id1(temp5_id1), .out_id2(temp5_id2));
comp_with_id c15(.opt(opt), .in1(temp4_s3), .in2(temp5_s4), .id1(temp4_id3), .id2(temp5_id4), .out1(temp5_s3), .out2(temp6_s4), .out_id1(temp5_id3), .out_id2(temp6_id4));
comp_with_id c16(.opt(opt), .in1(temp3_s5), .in2(temp3_s6), .id1(temp3_id5), .id2(temp3_id6), .out1(temp4_s5), .out2(temp4_s6), .out_id1(temp4_id5), .out_id2(temp4_id6));

endmodule


module mean_calculator(
	input opt,
	input [6:0] in_s0,
	input [6:0] in_s1,
	input [6:0] in_s2,
	input [6:0] in_s3,
	input [6:0] in_s4,
	input [6:0] in_s5,
	input [6:0] in_s6,
	output signed [3:0] mean
);
wire [6:0] sum;
assign sum = in_s0 + in_s1 + in_s2 + in_s3 + in_s4 + in_s5 + in_s6;
wire signed [3:0] signed_mean;
wire [3:0] unsigned_mean;
assign signed_mean = $signed(sum)/7;
assign unsigned_mean = sum/7;
assign mean = (opt) ? signed_mean : unsigned_mean;

endmodule

// pass helper
module judge(
	input opt,
	input [3:0] score,
	input [3:0] mean,
	input [1:0] a,
	input [2:0] b,
	output reg out
);
always@* begin
	if(~opt) begin
		out = ~ (score * (a + 1) + a + b < mean);
	end
	else begin
		if($signed(score) > 0)
			out = ~ ( $signed( $signed(score) * (a + 1) + a + b)  < $signed(mean) );
		else
			out = ~( $signed($signed(score) / $signed({1'b0,a + 1}) + $signed({1'b0,a}) + $signed({1'b0,b}))  < $signed(mean) );
	end
end

endmodule

// pass judger

module judge_network(
	input [3:0] in_s0,
	input [3:0] in_s1,
	input [3:0] in_s2,
	input [3:0] in_s3,
	input [3:0] in_s4,
	input [3:0] in_s5,
	input [3:0] in_s6,
	input opt,
	input [3:0] mean,
	input [1:0] a,
	input [2:0] b,
	output [2:0] out
);
// stage 1
wire stage_1_result;
judge stage_1_judge(
	.opt(opt),
	.score(in_s3),
	.mean(mean),
	.a(a),
	.b(b),
	.out(stage_1_result)
);

// stage 2
reg [3:0] stage2_input;
always@* begin
	case(stage_1_result)
		1'b0: stage2_input = in_s1;
		1'b1: stage2_input = in_s5;
	endcase
end
judge stage_2_judge(
	.opt(opt),
	.score(stage2_input),
	.mean(mean),
	.a(a),
	.b(b),
	.out(stage_2_result)
);

// stage 3
wire stage_3_result;
reg [3:0] stage3_input;
always@* begin
	case({stage_1_result, stage_2_result})
		2'b00: stage3_input = in_s0;
		2'b01: stage3_input = in_s2;
		2'b10: stage3_input = in_s4;
		2'b11: stage3_input = in_s6;
	endcase
end
judge stage_3_judge(
	.opt(opt),
	.score(stage3_input),
	.mean(mean),
	.a(a),
	.b(b),
	.out(stage_3_result)
);

assign out = {stage_1_result, stage_2_result, stage_3_result};

endmodule
