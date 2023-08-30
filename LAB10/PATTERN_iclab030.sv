`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
integer addr;
integer seed = 'd13;
integer dram_file;
integer i;
integer pat_count = 0;
parameter dram_path = "../00_TESTBED/DRAM/dram.dat";
logic rand_delay = 1;
logic rand_act_delay = 1;
logic limit_id_range = 0;
integer switch_user_prob = 2; // 1/10 chance
integer actual_switch_user_prob = 3;
logic no_err = 0;
logic check_seller_stock = 0;

logic [7:0] dram[((65536+256*8)-1):(65536)];
logic [31:0] gold_out;
logic do_check_seller = 0;

Action gold_act;
Action last_act = 0;
logic [3:0] gold_err;
logic gold_complete;

logic [4:0] record_id[255:0];

integer count_change_id = 0;

User_id user_id_for_test;
User_id seller_id_for_test;

//================================================================
// class
//================================================================
class Person;
	// mine save info
	User_id last_buyer;
	logic can_do_return;
	logic can_be_returned;
	// data in dram
	Shopping_His shop_history;
	Money money;
	Item_num		large_num;
	Item_num		medium_num;
	Item_num		small_num;
	User_Level	level;
	EXP					exp;
	function new(integer offset);
		this.last_buyer = 0;
		this.can_do_return = 0;
		this.can_be_returned = 0;
		{this.large_num,this.medium_num,this.small_num,this.level,this.exp} = {dram[65536+offset*8],dram[65537+offset*8],dram[65538+offset*8],dram[65539+offset*8]};
		{this.money,this.shop_history.item_ID,this.shop_history.item_num,this.shop_history.seller_ID} = {dram[65540+offset*8],dram[65541+offset*8],dram[65542+offset*8],dram[65543+offset*8]};
    endfunction
endclass

class Rand_id;
	rand User_id id_rand;
	logic limit_ot_not;
	function new(int seed);
		this.srandom(seed);
	endfunction
	function void pre_randomize ();
		this.limit_ot_not = limit_id_range;
	endfunction
	constraint limit{
		(!this.limit_ot_not) -> id_rand inside {[0:255]};
		(this.limit_ot_not) -> id_rand inside {[0:3]};
	}
endclass

class Rand_act;
	rand Action action_rand;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		action_rand inside {Return, Buy, Deposit, Check};
	}
endclass

class Rand_item;
	rand Item_id item_id_rand;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		item_id_rand inside {Large, Medium, Small};
	}
endclass

class Rand_item_num;
	rand Item_num item_num_rand;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		item_num_rand inside {[0:63]};
	}
endclass

class Rand_money;
	rand Money money_rand;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{
		money_rand inside {[0:65535]};
	}
endclass

class Rand_err;
	rand logic [3:0] err_rand;
	logic flag;
	Action now_act;
	function new(int seed);
		this.srandom(seed);
	endfunction
	function void pre_randomize ();
		this.now_act = gold_act;
		this.flag = no_err;
		//$display("gold act is: %d", this.now_act);
		//$display("gold error is: %d", gold_err);
	endfunction
	constraint limit{
		(flag == 1)                       -> err_rand inside {No_Err};
		(now_act == Buy     && flag == 0) -> err_rand inside {INV_Not_Enough, Out_of_money, INV_Full};
		(now_act == Check   && flag == 0) -> err_rand inside {No_Err};
		(now_act == Deposit && flag == 0) -> err_rand inside {No_Err, Wallet_is_Full};
		(now_act == Return  && flag == 0) -> err_rand inside {No_Err, Wrong_ID, Wrong_Num, Wrong_Item}; // wrong act deal in other place
	}
endclass


//================================================================
// wire & registers 
//================================================================
logic [63:0] write_to_dram;
logic [5:0] large_num;
logic [5:0] medium_num;
logic [5:0] small_num;
logic [1:0] level;
logic [11:0] exp;
logic [15:0] money;
logic [1:0] history_item;
logic [5:0] history_num;
logic [7:0] history_id;
Person all_user[255:0];

Rand_id rand_id_func = new(seed);
User_id user_id = 1;
User_id seller_id = 0;

Rand_item rand_item_func = new(seed);
Item_id gold_item;

Rand_item_num rand_item_num_func = new(seed);
Item_num gold_num;

Rand_money rand_money_func = new(seed);
Money gold_money;

Rand_act rand_act_func = new(seed);

Rand_err rand_err_func = new(seed);


//================================================================
// initial
//================================================================
initial $readmemh(dram_path, dram);

initial begin
write_dram_task;
reset_task;
@(negedge clk);

for(i=0;i<256;i=i+1) begin
	all_user[i] = new(i);
	record_id[i] = 0;
end
for(i=0;i<500;i=i+1) begin
	actual_switch_user_prob = 1;
	switch_user_task;
	actual_switch_user_prob = switch_user_prob;
	rand_act_func.randomize();
	gold_act = rand_act_func.action_rand;
	if(i > 50) begin
		rand_delay = 0;
		rand_act_delay = 0;
	end
	
	if(i > 400) begin
		gold_act = Buy;
		buy_task;
		if(gold_complete == 1) begin
			wait_out_valid_and_check_task;
			act_delay_task;
			gold_act = Return;
			return_task;
		end
	end
	else begin
		if(gold_act == Deposit)
			deposit_task;
		else if(gold_act == Check)
			check_task;
		else if(gold_act == Buy) begin
			gold_act = Buy;
			buy_task;
			if(gold_complete == 1) begin
				wait_out_valid_and_check_task;
				act_delay_task;
				gold_act = Return;
				return_task;
			end
		end
		else
			return_task;
	end
	wait_out_valid_and_check_task;
	act_delay_task;
end

// buy and record
// test 0: user switch and do other and return success
no_err = 1;
user_id = 0;
seller_id = 1;
switch_to_user_task;
post_buy_task;
user_id_for_test = user_id;
seller_id_for_test = seller_id;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 2;
seller_id = 3;
switch_to_user_task;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

do_check_seller = 1;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

deposit_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = user_id_for_test;
seller_id = seller_id_for_test;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 1: user buy and check and return;
post_buy_task;
user_id_for_test = user_id;
seller_id_for_test = seller_id;
wait_out_valid_and_check_task;
act_delay_task;

seller_id = 'd2;

do_check_seller = 0;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

seller_id = 'd1;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 2: user buy and check seller stock and return
post_buy_task;
user_id_for_test = user_id;
seller_id_for_test = seller_id;
wait_out_valid_and_check_task;
act_delay_task;

seller_id = 'd2;

do_check_seller = 1;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

seller_id = 'd1;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test3: user deposit and return
post_buy_task;
user_id_for_test = user_id;
seller_id_for_test = seller_id;
wait_out_valid_and_check_task;
act_delay_task;

deposit_task;
wait_out_valid_and_check_task;
act_delay_task;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test3: user deposit and return
post_buy_task;
user_id_for_test = user_id;
seller_id_for_test = seller_id;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd2;
seller_id = 'd0;
switch_to_user_task;
do_check_seller = 1;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;
user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 4: return double time with correct item id num
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 5: seller do buy
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

switch_to_seller_task;
user_id = 1;
seller_id = 2;

post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 6: seller do check 1
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

switch_to_seller_task;
user_id = 1;
seller_id = 2;

do_check_seller = 0;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 7: seller do check 2
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

switch_to_seller_task;
user_id = 1;
seller_id = 2;

do_check_seller = 1;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

do_check_seller = 0;
// test 8: seller do return
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

switch_to_seller_task;
user_id = 1;
seller_id = 2;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// test 5: seller do deposit
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

switch_to_seller_task;
user_id = 1;
seller_id = 2;

deposit_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;
seller_id = 'd1;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// seller sell to another
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd2;

switch_to_user_task;
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// seller sell is returned
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd2;

switch_to_user_task;
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
act_delay_task;

// seller is checked
post_buy_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd2;

switch_to_user_task;
do_check_seller = 1;
post_check_task;
wait_out_valid_and_check_task;
act_delay_task;

user_id = 'd0;

switch_to_user_task;
post_return_task;
wait_out_valid_and_check_task;
$finish;
end

//================================================================
// task
//================================================================
task reset_task; begin
	// valid
	inf.rst_n = 1;
	inf.act_valid = 0;
	inf.amnt_valid = 0;
	inf.id_valid = 0;
	inf.item_valid = 0;
	inf.num_valid = 0;
	// output
	inf.D = 'bx;
	// reset
	#(1) inf.rst_n = 0;
	#(20) inf.rst_n = 1;
end endtask

task show_info(integer id); begin
$display("|---------------------------------------------------------------------------------------------------------------------------|");
$display("|                                              displaying  id:      %5d                                                   |",id);
$display("|       large_num: %5d   |   medium_num:   %5d   |   small_num:   %5d   |   level:      %5d   |   exp: %5d        |",all_user[id].large_num,all_user[id].medium_num,all_user[id].small_num,all_user[id].level, all_user[id].exp);
$display("|       money:     %5d   |   history_item: %5d   |   history_num: %5d   |   history_id: %5d                         |",all_user[id].money,all_user[id].shop_history.item_ID,all_user[id].shop_history.item_num,all_user[id].shop_history.seller_ID);
$display("|---------------------------------------------------------------------------------------------------------------------------|\n");
end endtask


task write_dram_task; begin
	dram_file = $fopen(dram_path,"w");
	for(addr='d65536; addr< ('d65536 + 256*8); addr=addr+'h8) begin
		large_num = $random(seed)%'d50;
		medium_num = $random(seed)%'d50;
		small_num = $random(seed)%'d50;
		level = $random(seed)%'d4;
		if(level === 'd0)begin
			exp = 'd0;
		end
		else if(level === 'd1)begin
			exp = $random(seed)%'d4000;
		end
		else if(level === 'd2)begin
			exp = $random(seed)%'d2500;
		end
		else if(level === 'd3)begin
			exp = $random(seed)%'d1000;
		end
		money = $random(seed)%'d5535;
		history_item = $random(seed)%'d4;
		history_num = $random(seed)%'d64;
		history_id = $random(seed)%'d256;
		write_to_dram = {large_num, medium_num, small_num, level, exp, money, history_item, history_num, history_id};
		$fwrite(dram_file, "@%5h\n", addr);
		$fwrite(dram_file, "%h ", write_to_dram[63:56]);
		$fwrite(dram_file, "%h ", write_to_dram[55:48]);
		$fwrite(dram_file, "%h ", write_to_dram[47:40]);
		$fwrite(dram_file, "%h\n", write_to_dram[39:32]);
		$fwrite(dram_file, "@%5h\n", addr+'h4);
		$fwrite(dram_file, "%h ", write_to_dram[31:24]);
		$fwrite(dram_file, "%h ", write_to_dram[23:16]);
		$fwrite(dram_file, "%h ", write_to_dram[15:8]);
		$fwrite(dram_file, "%h\n", write_to_dram[7:0]);
    end
    $fclose(dram_file);
end endtask

//================================================================
// delay task
//================================================================
task valid_delay_task; begin
	if(rand_delay)
		repeat(({$random(seed)} % 'd5 + 'd1)) @(negedge clk);
	else
		@(negedge clk);
end endtask

task act_delay_task; begin
	if(rand_delay)
		repeat(({$random(seed)} % 'd9 + 'd2)) @(negedge clk);
	else
		repeat(2)@(negedge clk);
end endtask

//================================================================
// switch user
//================================================================
task switch_user_task; begin
	if({$random(seed)} % actual_switch_user_prob == 'd0) begin
		rand_id_func.randomize();
		user_id = rand_id_func.id_rand;
		count_change_id = 0;
		while(record_id[user_id] >= 'd2 && count_change_id < 10) begin
			rand_id_func.randomize();
			user_id = rand_id_func.id_rand;
			count_change_id = count_change_id + 1;
		end
		inf.id_valid = 1;
		inf.D = user_id;
		record_id[user_id] = record_id[user_id] + 1;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		valid_delay_task;
	end
end endtask

task switch_to_user_task; begin
		inf.id_valid = 1;
		inf.D = user_id;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		valid_delay_task;
end endtask

task switch_to_seller_task; begin
		inf.id_valid = 1;
		inf.D = seller_id;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		valid_delay_task;
end endtask

//================================================================
// check
//================================================================
task check_task; begin
	// set input info
	gold_act = Check;
	rand_err_func.randomize();
	gold_err = rand_err_func.err_rand;
	inf.act_valid = 1;
	inf.D.d_act = gold_act;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;

	valid_delay_task;
	
	if({$random(seed)} % 'd2 == 'd1) begin
		rand_id_func.randomize();
		seller_id = rand_id_func.id_rand;
		count_change_id = 0;
		while(record_id[seller_id] >= 'd2 && count_change_id < 10) begin
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
			count_change_id = count_change_id + 1;
		end
		while(seller_id == user_id) begin
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
		end
		inf.id_valid = 1;
		inf.D = seller_id;
		record_id[seller_id] = record_id[seller_id] + 1;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		check_seller_stock = 1;
	end
	else
		check_seller_stock = 0;
	// calculate answer and set change
	if(check_seller_stock == 1) begin
		gold_out = {14'd0,all_user[seller_id].large_num,all_user[seller_id].medium_num,all_user[seller_id].small_num};
		all_user[seller_id].can_be_returned = 0;
		all_user[seller_id].can_do_return = 0;
		all_user[user_id].can_be_returned = 0;
		all_user[user_id].can_do_return = 0;
	end
	else begin
		gold_out = {16'd0,all_user[user_id].money};
		all_user[user_id].can_be_returned = 0;
		all_user[user_id].can_do_return = 0;
	end
	gold_complete = 1;
end endtask

task post_check_task; begin
	// set input info
	gold_act = Check;
	gold_err = No_Err;
	// input
	inf.act_valid = 1;
	inf.D.d_act = gold_act;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;
	valid_delay_task;
	
	if(do_check_seller) begin
		inf.id_valid = 1;
		inf.D = seller_id;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
	end
	// calculate answer and set change
	if(do_check_seller == 1) begin
		gold_out = {14'd0,all_user[seller_id].large_num,all_user[seller_id].medium_num,all_user[seller_id].small_num};
		all_user[seller_id].can_be_returned = 0;
		all_user[seller_id].can_do_return = 0;
		all_user[user_id].can_be_returned = 0;
		all_user[user_id].can_do_return = 0;
	end
	else begin
		gold_out = {16'd0,all_user[user_id].money};
		all_user[user_id].can_be_returned = 0;
		all_user[user_id].can_do_return = 0;
	end
	gold_complete = 1;
end endtask

//================================================================
// deposit
//================================================================
task deposit_task; begin
	// set input info
	gold_act = Deposit;
	rand_err_func.randomize();
	gold_err = rand_err_func.err_rand;
	if(all_user[user_id].money < 100)
		gold_err = No_Err;
	else if(all_user[user_id].money > 'd65500)
		gold_err = Wallet_is_Full;
	
	if(gold_err == No_Err) begin
		rand_money_func.randomize();
		gold_money = rand_money_func.money_rand;
		while(all_user[user_id].money + gold_money >= 'd65530) begin
			rand_money_func.randomize();
			gold_money = rand_money_func.money_rand;
		end
		gold_complete = 1;
	end else begin
		rand_money_func.randomize();
		gold_money = rand_money_func.money_rand;
		while(all_user[user_id].money + gold_money < 'd65536) begin
			rand_money_func.randomize();
			gold_money = rand_money_func.money_rand;
		end
		gold_complete = 0;
	end
	// input
	inf.act_valid = 1;
	inf.D = gold_act;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D = 'dx;
	
	valid_delay_task;

	inf.amnt_valid = 1;
	inf.D = gold_money;
	@(negedge clk);
	inf.amnt_valid = 0;
	inf.D = 'dx;
	// calculate and set change
	if(gold_complete == 1) begin
		gold_out = {16'd0,all_user[user_id].money + gold_money};
		all_user[user_id].can_be_returned = 0;
		all_user[user_id].can_do_return = 0;
		all_user[user_id].money = all_user[user_id].money + gold_money;
	end
	else begin
		gold_out = 0;
	end
end endtask

//================================================================
// buy
//================================================================
Item_num now_seller_item_num;
Item_num now_user_item_num;
integer price_per_item;
integer max_cost;
integer fee;
integer exp_earned;
integer out_count_try = 0;
integer in_count_try = 0;
integer success = 0;
task buy_task; begin
	// set input info
	in_count_try = 0;
	out_count_try = 0;
	gold_act = Buy;
	success = 0;
	
	while(out_count_try < 2 && success == 0) begin
		in_count_try = 0;
		rand_id_func.randomize();
		seller_id = rand_id_func.id_rand;
		count_change_id = 0;
		while(record_id[seller_id] >= 'd2 && count_change_id < 10) begin
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
			count_change_id = count_change_id + 1;
		end
		while(seller_id == user_id) begin
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
		end
		rand_item_func.randomize();
		gold_item = rand_item_func.item_id_rand;
		// cant done err
		if(gold_item == Small) begin
			now_user_item_num = all_user[user_id].small_num;
			now_seller_item_num = all_user[seller_id].small_num;
			price_per_item = 'd100;
		end else if(gold_item == Medium) begin
			now_user_item_num = all_user[user_id].medium_num;
			now_seller_item_num = all_user[seller_id].medium_num;
			price_per_item = 'd200;
		end else if(gold_item == Large) begin
			now_user_item_num = all_user[user_id].large_num;
			now_seller_item_num = all_user[seller_id].large_num;
			price_per_item = 'd300;
		end
		max_cost = price_per_item * 'd63;
		rand_err_func.randomize();
		gold_err = rand_err_func.err_rand;
		if(out_count_try < 1 && gold_err == INV_Full) begin				
			rand_err_func.randomize();
			gold_err = rand_err_func.err_rand;
		end
		while( (gold_err==INV_Full&&now_user_item_num=='d0)  ||  (gold_err==INV_Not_Enough&&now_seller_item_num=='d63) ||  (gold_err==Out_of_money&&all_user[user_id].money>=max_cost)) begin
			rand_err_func.randomize();
			gold_err = rand_err_func.err_rand;
		end

		// get fee
		if(all_user[user_id].level==Platinum)
			fee = 'd10;
		else if(all_user[user_id].level==Gold)
			fee = 'd30;
		else if(all_user[user_id].level==Silver)
			fee = 'd50;
		else
			fee = 'd70;

		if(gold_err==INV_Full) begin
			gold_complete = 0;
			gold_out = 0;
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			while(gold_num + now_user_item_num < 64 && in_count_try < 2) begin
				rand_item_num_func.randomize();
				gold_num = rand_item_num_func.item_num_rand;
				in_count_try = in_count_try + 1;
			end
			if(in_count_try != 2)
				success = 1;
		end else if(gold_err==INV_Not_Enough) begin
			gold_complete = 0;
			gold_out = 0;
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			while( (now_seller_item_num >= gold_num || gold_num + now_user_item_num > 63) && in_count_try < 5) begin
				rand_item_num_func.randomize();
				gold_num = rand_item_num_func.item_num_rand;
				in_count_try = in_count_try + 1;
			end
			if(in_count_try != 5)
				success = 1;
		end else if(gold_err==Out_of_money) begin
			gold_complete = 0;
			gold_out = 0;
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			while( ( (gold_num * price_per_item) + fee < all_user[user_id].money || now_seller_item_num < gold_num || gold_num + now_user_item_num > 63 ) && in_count_try < 10) begin
				rand_item_num_func.randomize();
				gold_num = rand_item_num_func.item_num_rand;
				in_count_try = in_count_try + 1;
			end
			if(in_count_try != 10)
				success = 1;
		end
		out_count_try = out_count_try + 1;
		if({$random(seed)}%'d2 == 0)
			break;
	end
	if(success == 0) begin
		gold_err = No_Err;
	end
	// give up
	if(gold_err==No_Err) begin
		gold_complete = 1;
		rand_item_num_func.randomize();
		gold_num = rand_item_num_func.item_num_rand;
		in_count_try = 0;
		while( ( (gold_num * price_per_item) + fee > all_user[user_id].money || now_seller_item_num < gold_num || gold_num + now_user_item_num > 63) && in_count_try < 100) begin
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			in_count_try = in_count_try + 1;
		end
		if(in_count_try==100) begin
			no_err = 1;
			deposit_task;
			wait_out_valid_and_check_task;
			act_delay_task;
			no_err = 0;
		end
		in_count_try = 0;
		while( ( (gold_num * price_per_item) + fee > all_user[user_id].money || now_seller_item_num < gold_num || gold_num + now_user_item_num > 63) && in_count_try < 100) begin
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			in_count_try = in_count_try + 1;
		end
		// update info
		// update money
		all_user[user_id].money = all_user[user_id].money - (gold_num * price_per_item) - fee;
		
		if(all_user[seller_id].money + (gold_num * price_per_item) > 'd65535)
			all_user[seller_id].money = 'd65535;
		else
			all_user[seller_id].money = all_user[seller_id].money + (gold_num * price_per_item);
		// update num
		if(gold_item == Small) begin
			all_user[user_id].small_num = all_user[user_id].small_num + gold_num;
			all_user[seller_id].small_num = all_user[seller_id].small_num - gold_num;
			exp_earned = 'd20 * gold_num;
		end else if(gold_item == Medium) begin
			all_user[user_id].medium_num = all_user[user_id].medium_num + gold_num;
			all_user[seller_id].medium_num = all_user[seller_id].medium_num - gold_num;
			exp_earned = 'd40 * gold_num;
		end else if(gold_item == Large) begin
			all_user[user_id].large_num = all_user[user_id].large_num + gold_num;
			all_user[seller_id].large_num = all_user[seller_id].large_num - gold_num;
			exp_earned = 'd60 * gold_num;
		end
		// update exp
		if(all_user[user_id].level==Gold&&all_user[user_id].exp+exp_earned>='d4000) begin
			all_user[user_id].level = Platinum;
			all_user[user_id].exp = 0;
		end else if(all_user[user_id].level==Silver&&all_user[user_id].exp+exp_earned>='d2500) begin
			all_user[user_id].level = Gold;
			all_user[user_id].exp = 0;
		end else if(all_user[user_id].level==Copper&&all_user[user_id].exp+exp_earned>='d1000) begin
			all_user[user_id].level = Silver;
			all_user[user_id].exp = 0;
		end else if(all_user[user_id].level==Platinum) begin
			all_user[user_id].level = Platinum;
			all_user[user_id].exp = 0;
		end else begin
			all_user[user_id].exp = all_user[user_id].exp + exp_earned;
		end
		// update shop history
		all_user[user_id].shop_history.item_ID = gold_item;
		all_user[user_id].shop_history.item_num = gold_num;
		all_user[user_id].shop_history.seller_ID = seller_id;
		// record my flag
		all_user[user_id].can_do_return = 1;
		all_user[user_id].can_be_returned = 0;
		all_user[seller_id].can_do_return = 0;
		all_user[seller_id].can_be_returned = 1;
		all_user[seller_id].last_buyer = user_id;
		gold_out = {all_user[user_id].money,all_user[user_id].shop_history};
	end
	
	// input
	inf.act_valid = 1;
	inf.D.d_act = Buy;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;

	valid_delay_task;

	inf.item_valid = 1;
	inf.D = gold_item;
	@(negedge clk);
	inf.item_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.num_valid = 1;
	inf.D = gold_num;
	@(negedge clk);
	inf.num_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.id_valid = 1;
	inf.D = seller_id;
	record_id[seller_id] = record_id[seller_id] + 1;
	@(negedge clk);
	inf.id_valid = 0;
	inf.D = 'dx;

end endtask


task post_buy_task; begin
	// set input info
	gold_act = Buy;
	gold_err = No_Err;
	gold_complete = 1;
		
	rand_item_func.randomize();
	gold_item = rand_item_func.item_id_rand;
	// cant done err
	if(gold_item == Small) begin
		if(all_user[user_id].small_num < 63 && all_user[seller_id].small_num > 0)
			gold_num = 1;
		else
			gold_item = Medium;
		price_per_item = 'd100;
	end
	if(gold_item == Medium) begin
		if(all_user[user_id].medium_num < 63 && all_user[seller_id].medium_num > 0)
			gold_num = 1;
		else
			gold_item = Large;
		price_per_item = 'd200;
	end
	if(gold_item == Large) begin
		if(all_user[user_id].large_num < 63 && all_user[seller_id].large_num > 0)
			gold_num = 1;
		else
			gold_num = 0;
		price_per_item = 'd300;
	end


	// get fee
	if(all_user[user_id].level==Platinum)
		fee = 'd10;
	else if(all_user[user_id].level==Gold)
		fee = 'd30;
	else if(all_user[user_id].level==Silver)
		fee = 'd50;
	else
		fee = 'd70;

	// update info
	// update money
	all_user[user_id].money = all_user[user_id].money - (gold_num * price_per_item) - fee;
	
	if(all_user[seller_id].money + (gold_num * price_per_item) > 'd65535)
		all_user[seller_id].money = 'd65535;
	else
		all_user[seller_id].money = all_user[seller_id].money + (gold_num * price_per_item);
	// update num
	if(gold_item == Small) begin
		all_user[user_id].small_num = all_user[user_id].small_num + gold_num;
		all_user[seller_id].small_num = all_user[seller_id].small_num - gold_num;
		exp_earned = 'd20 * gold_num;
	end else if(gold_item == Medium) begin
		all_user[user_id].medium_num = all_user[user_id].medium_num + gold_num;
		all_user[seller_id].medium_num = all_user[seller_id].medium_num - gold_num;
		exp_earned = 'd40 * gold_num;
	end else if(gold_item == Large) begin
		all_user[user_id].large_num = all_user[user_id].large_num + gold_num;
		all_user[seller_id].large_num = all_user[seller_id].large_num - gold_num;
		exp_earned = 'd60 * gold_num;
	end
	// update exp
	if(all_user[user_id].level==Gold&&all_user[user_id].exp+exp_earned>='d4000) begin
		all_user[user_id].level = Platinum;
		all_user[user_id].exp = 0;
	end else if(all_user[user_id].level==Silver&&all_user[user_id].exp+exp_earned>='d2500) begin
		all_user[user_id].level = Gold;
		all_user[user_id].exp = 0;
	end else if(all_user[user_id].level==Copper&&all_user[user_id].exp+exp_earned>='d1000) begin
		all_user[user_id].level = Silver;
		all_user[user_id].exp = 0;
	end else if(all_user[user_id].level==Platinum) begin
		all_user[user_id].level = Platinum;
		all_user[user_id].exp = 0;
	end else begin
		all_user[user_id].exp = all_user[user_id].exp + exp_earned;
	end
	// update shop history
	all_user[user_id].shop_history.item_ID = gold_item;
	all_user[user_id].shop_history.item_num = gold_num;
	all_user[user_id].shop_history.seller_ID = seller_id;
	// record my flag
	all_user[user_id].can_do_return = 1;
	all_user[user_id].can_be_returned = 0;
	all_user[seller_id].can_do_return = 0;
	all_user[seller_id].can_be_returned = 1;
	all_user[seller_id].last_buyer = user_id;
	gold_out = {all_user[user_id].money,all_user[user_id].shop_history};

	
	// input
	inf.act_valid = 1;
	inf.D.d_act = Buy;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;

	valid_delay_task;

	inf.item_valid = 1;
	inf.D = gold_item;
	@(negedge clk);
	inf.item_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.num_valid = 1;
	inf.D = gold_num;
	@(negedge clk);
	inf.num_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.id_valid = 1;
	inf.D = seller_id;
	record_id[seller_id] = record_id[seller_id] + 1;
	@(negedge clk);
	inf.id_valid = 0;
	inf.D = 'dx;

end endtask


//================================================================
// return
//================================================================
logic now_can_do_return;
User_id real_seller_id;
task return_task; begin
	// set input info
	gold_act = Return;
	real_seller_id = all_user[user_id].shop_history.seller_ID;
	if(all_user[user_id].can_do_return == 1&& all_user[real_seller_id].can_be_returned == 1 && all_user[real_seller_id].last_buyer == user_id)
		now_can_do_return = 1;
	else
		now_can_do_return = 0;
	// if cant do return means only wrong act is legal
	if(now_can_do_return) begin
		rand_err_func.randomize();
		gold_err = rand_err_func.err_rand;
		if(gold_err == No_Err) begin
			rand_err_func.randomize();
			gold_err = rand_err_func.err_rand;
		end
		if(gold_err == Wrong_ID) begin
			// id
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
			count_change_id = 0;
			while(record_id[seller_id] >= 'd2 && count_change_id < 10) begin
				rand_id_func.randomize();
				seller_id = rand_id_func.id_rand;
				count_change_id = count_change_id + 1;
			end
			while(seller_id == user_id || seller_id == real_seller_id) begin
				rand_id_func.randomize();
				seller_id = rand_id_func.id_rand;
			end
			// num
			if({$random(seed) % 'd2 == 1})
				gold_num = all_user[user_id].shop_history.item_num;
			else begin
				rand_item_num_func.randomize();
				gold_num = rand_item_num_func.item_num_rand;
			end
			// item
			if({$random(seed) % 'd2 == 1})
				gold_item = all_user[user_id].shop_history.item_ID;
			else begin
				rand_item_func.randomize();
				gold_item = rand_item_func.item_id_rand;
			end
		end
		else if(gold_err == Wrong_Num) begin
			// id
			seller_id = real_seller_id;
			// num
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
			while(gold_num == all_user[user_id].shop_history.item_num) begin
				rand_item_num_func.randomize();
				gold_num = rand_item_num_func.item_num_rand;
			end
			// item id
			if({$random(seed) % 'd2 == 1})
				gold_item = all_user[user_id].shop_history.item_ID;
			else begin
				rand_item_func.randomize();
				gold_item = rand_item_func.item_id_rand;
			end
		end
		else if(gold_err == Wrong_Item) begin
			seller_id = real_seller_id;
			gold_num = all_user[user_id].shop_history.item_num;
			rand_item_func.randomize();
			gold_item = rand_item_func.item_id_rand;
			while(gold_item == all_user[user_id].shop_history.item_ID) begin
				rand_item_func.randomize();
				gold_item = rand_item_func.item_id_rand;
			end
		end
		else if(gold_err == No_Err) begin
			seller_id = real_seller_id;
			gold_num = all_user[user_id].shop_history.item_num;
			gold_item = all_user[user_id].shop_history.item_ID;
		end
	end
	else begin
		// else dont care -> random input right or false
		if({$random(seed) % 'd2 == 1})
			seller_id = real_seller_id;
		else begin
			rand_id_func.randomize();
			seller_id = rand_id_func.id_rand;
			count_change_id = 0;
			while(record_id[seller_id] >= 'd2 && count_change_id < 10) begin
				rand_id_func.randomize();
				seller_id = rand_id_func.id_rand;
				count_change_id = count_change_id + 1;
			end
			while(seller_id == user_id) begin
				rand_id_func.randomize();
				seller_id = rand_id_func.id_rand;
			end
		end
		if({$random(seed) % 'd2 == 1})
			gold_item = all_user[user_id].shop_history.item_ID;
		else begin
			rand_item_func.randomize();
			gold_item = rand_item_func.item_id_rand;
		end
		if({$random(seed) % 'd2 == 1})
			gold_num = all_user[user_id].shop_history.item_num;
		else begin
			rand_item_num_func.randomize();
			gold_num = rand_item_num_func.item_num_rand;
		end
		gold_err = Wrong_act;
	end
	
	if(gold_err == No_Err) begin
		if(gold_item == Small) begin
			price_per_item = 'd100;
		end else if(gold_item == Medium) begin
			price_per_item = 'd200;
		end else if(gold_item == Large) begin
			price_per_item = 'd300;
		end
		// update info
		// update money
		all_user[user_id].money = all_user[user_id].money + gold_num * price_per_item;
		all_user[seller_id].money = all_user[seller_id].money - (gold_num * price_per_item);
		// update num
		if(gold_item == Small) begin
			all_user[user_id].small_num = all_user[user_id].small_num - gold_num;
			all_user[seller_id].small_num = all_user[seller_id].small_num + gold_num;
		end else if(gold_item == Medium) begin
			all_user[user_id].medium_num = all_user[user_id].medium_num - gold_num;
			all_user[seller_id].medium_num = all_user[seller_id].medium_num + gold_num;
		end else if(gold_item == Large) begin
			all_user[user_id].large_num = all_user[user_id].large_num - gold_num;
			all_user[seller_id].large_num = all_user[seller_id].large_num + gold_num;
		end
		// record my flag
		all_user[user_id].can_do_return = 0;
		all_user[user_id].can_be_returned = 0;
		all_user[seller_id].can_do_return = 0;
		all_user[seller_id].can_be_returned = 0;
		// set out
		gold_complete = 1;
		gold_out = {14'd0,all_user[user_id].large_num,all_user[user_id].medium_num,all_user[user_id].small_num};
	end else begin
		gold_complete = 0;
		gold_out = 0;
	end
	
	// input
	inf.act_valid = 1;
	inf.D.d_act = gold_act;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;

	valid_delay_task;

	inf.item_valid = 1;
	inf.D = gold_item;
	@(negedge clk);
	inf.item_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.num_valid = 1;
	inf.D = gold_num;
	@(negedge clk);
	inf.num_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.id_valid = 1;
	inf.D = seller_id;
	record_id[seller_id] = record_id[seller_id] + 1;
	@(negedge clk);
	inf.id_valid = 0;
	inf.D = 'dx;

end endtask

task post_return_task; begin
	// set input info
	gold_act = Return;
	real_seller_id = all_user[user_id].shop_history.seller_ID;
	if(all_user[user_id].can_do_return == 1&& all_user[real_seller_id].can_be_returned == 1 && all_user[real_seller_id].last_buyer == user_id && real_seller_id == seller_id)
		now_can_do_return = 1;
	else
		now_can_do_return = 0;
		
	gold_num = all_user[user_id].shop_history.item_num;
	gold_item = all_user[user_id].shop_history.item_ID;
	// if cant do return means only wrong act is legal
	if(now_can_do_return) begin
		gold_err = No_Err;
	end
	else begin
		gold_err = Wrong_act;
	end
	
	if(gold_err == No_Err) begin
		if(gold_item == Small) begin
			price_per_item = 'd100;
		end else if(gold_item == Medium) begin
			price_per_item = 'd200;
		end else if(gold_item == Large) begin
			price_per_item = 'd300;
		end
		// update info
		// update money
		all_user[user_id].money = all_user[user_id].money + gold_num * price_per_item;
		all_user[seller_id].money = all_user[seller_id].money - (gold_num * price_per_item);
		// update num
		if(gold_item == Small) begin
			all_user[user_id].small_num = all_user[user_id].small_num - gold_num;
			all_user[seller_id].small_num = all_user[seller_id].small_num + gold_num;
		end else if(gold_item == Medium) begin
			all_user[user_id].medium_num = all_user[user_id].medium_num - gold_num;
			all_user[seller_id].medium_num = all_user[seller_id].medium_num + gold_num;
		end else if(gold_item == Large) begin
			all_user[user_id].large_num = all_user[user_id].large_num - gold_num;
			all_user[seller_id].large_num = all_user[seller_id].large_num + gold_num;
		end
		// record my flag
		all_user[user_id].can_do_return = 0;
		all_user[user_id].can_be_returned = 0;
		all_user[seller_id].can_do_return = 0;
		all_user[seller_id].can_be_returned = 0;
		// set out
		gold_complete = 1;
		gold_out = {14'd0,all_user[user_id].large_num,all_user[user_id].medium_num,all_user[user_id].small_num};
	end else begin
		gold_complete = 0;
		gold_out = 0;
	end
	
	// input
	inf.act_valid = 1;
	inf.D.d_act = gold_act;
	@(negedge clk);
	inf.act_valid = 0;
	inf.D.d_act = 'dx;

	valid_delay_task;

	inf.item_valid = 1;
	inf.D = gold_item;
	@(negedge clk);
	inf.item_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.num_valid = 1;
	inf.D = gold_num;
	@(negedge clk);
	inf.num_valid = 0;
	inf.D = 'dx;

	valid_delay_task;

	inf.id_valid = 1;
	inf.D = seller_id;
	record_id[seller_id] = record_id[seller_id] + 1;
	@(negedge clk);
	inf.id_valid = 0;
	inf.D = 'dx;

end endtask

//================================================================
// wait outvalid
//================================================================
task wait_out_valid_and_check_task; begin
	while(inf.out_valid !== 1)
		@(negedge clk);
	if(inf.complete !== gold_complete || inf.err_msg !== gold_err || inf.out_info  !== gold_out) begin
		$display("Wrong Answer");
		$finish;
	end
end endtask

endprogram