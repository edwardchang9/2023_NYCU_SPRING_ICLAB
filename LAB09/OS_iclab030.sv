module OS(input clk, INF.OS_inf inf);
import usertype::*;

//input  
// Pattern
//rst_n, D, id_valid, act_valid, item_valid, amnt_valid, num_valid, 
// Bridge
//C_out_valid, C_data_r,

//output 
// Pattern
//out_valid, err_msg,  complete, out_info, 
// Bridge
//C_addr, C_data_w, C_in_valid, C_r_wb

State current_state;
State next_state;

logic user_info_valid;
logic save_user_info_valid;
assign user_info_valid = save_user_info_valid || inf.C_out_valid;
Item_id save_item_id;
Item_num save_num;
User_id save_seller_id;
User_id save_user_id;
User_id save_check_id;
Person_info d_out;
Dram_out_change_format d_out_change;
assign d_out_change = inf.C_data_r;
assign d_out.user = {d_out_change.e[3],d_out_change.e[2],d_out_change.e[1],d_out_change.e[0]};
assign d_out.shop = {d_out_change.e[7],d_out_change.e[6],d_out_change.e[5],d_out_change.e[4]};

Person_info d_in;
Dram_out_change_format d_in_change;
assign {d_in_change.e[3],d_in_change.e[2],d_in_change.e[1],d_in_change.e[0]} = d_in.user;
assign {d_in_change.e[7],d_in_change.e[6],d_in_change.e[5],d_in_change.e[4]} = d_in.shop;

Person_info user;
Person_info seller;
Person_info next_user;
Person_info next_seller;
Person_info next_deposit_user;
Person_info next_return_user;
Person_info next_return_seller;
Shopping_His next_shop_history;


Record [255:0] all_record;

logic user_full;
logic seller_not_enough;
logic out_of_money;
logic [6:0] buy_fee;
logic [9:0] price;
logic [14:0] buy_money_needed;
logic [14:0] buy_money_needed_without_fee;
logic [11:0] earned_exp;
logic upgrade_level;
User_Level next_level;
logic [11:0] next_exp;
logic buy_success;
assign buy_success = (~user_full && ~out_of_money && ~seller_not_enough);
logic [15:0] save_amnt;
logic [16:0] next_money;
logic wallet_is_full;

logic wrong_operation;
logic wrong_id;
logic wrong_item;
logic wrong_number;
logic return_success;
assign return_success = (~wrong_id) && (~wrong_item) && (~wrong_number) && (~wrong_operation);
My_action save_action;

logic is_check_user_stock;

Err_Msg save_err;
logic save_complete;
out_format save_out_info;

always_ff @(posedge clk) begin
	if(inf.C_out_valid && !save_user_info_valid) begin
		user <= d_out;
	end
	else begin 
		case(current_state)
		S_BUY_CAL:
			if(buy_success)
				user <= next_user;
		S_DEPOSIT_CAL:
			if(!wallet_is_full)
				user <= next_deposit_user;
		S_RETURN_CAL:
				user <= next_return_user;
		default: user <= user;
		endcase
	end
end

always_ff @(posedge clk) begin
	case(current_state)
	S_BUY_GET_SELLER_WAIT, S_CHECK_REQUEST_WAIT, S_RETURN_GET_SELLER_WAIT:
		if(inf.C_out_valid) begin
			seller <= d_out;
		end
	S_BUY_CAL: begin
		seller <= next_seller;
	end
	S_RETURN_CAL: begin
		seller <= next_return_seller;
	end 
	default: seller <= seller;
	endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		save_user_info_valid <= 0;
	end else
		if(current_state == S_IDLE && inf.id_valid)
			save_user_info_valid <= 0;
		else if(inf.C_out_valid)
			save_user_info_valid <= 1;
		else
			save_user_info_valid <= user_info_valid;
end

logic dram_enable;
assign dram_enable = (current_state == S_IDLE && inf.id_valid) || current_state == S_BUY_GET_SELLER_REQUEST || current_state == S_RETURN_GET_SELLER_REQUEST || current_state == S_CHECK_REQUEST || current_state == S_WRITE_SELLER_REQUEST || current_state == S_WRITE_USER_REQUEST;
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.C_in_valid <= 0;
	end else
		if(dram_enable)
			inf.C_in_valid <= 1;
		else
			inf.C_in_valid <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.C_r_wb <= 0;
	end else
		if((current_state == S_IDLE && inf.id_valid) || current_state == S_BUY_GET_SELLER_REQUEST || current_state == S_RETURN_GET_SELLER_REQUEST || current_state == S_CHECK_REQUEST)
			inf.C_r_wb <= 1;
		else
			inf.C_r_wb <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.C_addr <= 0;
	end
	else
		case(current_state)
		S_IDLE:
			if(inf.id_valid)
				inf.C_addr <= inf.D.d_id;
		S_BUY_GET_SELLER_REQUEST, S_WRITE_SELLER_REQUEST:
			inf.C_addr <= save_seller_id;
		S_CHECK_REQUEST:
			inf.C_addr <= save_seller_id;
		S_RETURN_GET_SELLER_REQUEST:
			inf.C_addr <= user.user.shop_history.seller_ID;
		S_WRITE_USER_REQUEST:
			inf.C_addr <= save_user_id;
		default: inf.C_addr <= 0;
		endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.C_data_w <= 0;
	end
	else
		inf.C_data_w <= d_in_change;
end

always_ff @(negedge clk or negedge inf.rst_n) begin
if(!inf.rst_n)
	d_in <= 0;
else
	case(current_state)
	S_WRITE_SELLER_REQUEST: d_in <= seller;
	S_WRITE_USER_REQUEST: d_in <= user;
	default: d_in <= 0;
	endcase
end

always_ff @(posedge clk) begin
	if(inf.act_valid)
		case(inf.D.d_act)
		Check: save_action <= Is_Check;
		Deposit: save_action <= Is_Deposit;
		Buy: save_action <= Is_Buy;
		Return: save_action <= Is_Return;
		endcase
	else
		save_action <= save_action;
end

always_ff @(posedge clk) begin
	if(inf.item_valid)
		save_item_id <= inf.D.d_item;
	else
		save_item_id <= save_item_id;
end

always_ff @(posedge clk) begin
	if(inf.num_valid)
		save_num <= inf.D.d_item_num;
	else
		save_num <= save_num;
end

always_ff @(posedge clk) begin
	if(inf.id_valid && (current_state == S_BUY_READ || current_state == S_RETURN_READ || current_state == S_CHECK_READ))
		save_seller_id <= inf.D.d_id;
	else
		save_seller_id <= save_seller_id;
end

always_ff @(posedge clk) begin
	if(inf.id_valid && current_state == S_IDLE)
		save_user_id <= inf.D.d_id;
	else
		save_user_id <= save_user_id;
end

always_ff @(posedge clk) begin
	if(inf.amnt_valid)
		save_amnt <= inf.D.d_money;
	else
		save_amnt <= save_amnt;
end

/*
typedef struct packed {
	Item_num		large_num;
	Item_num		medium_num;
	Item_num		small_num;
	User_Level	level;
	EXP					exp;
}	Shop_Info; //Shop info

typedef struct packed {
	Money money; 
	Shopping_His shop_history;
}	User_Info; //User info

*/


// buy
logic [6:0] result_num;
logic [5:0] in_1;
assign result_num = save_num + in_1;
always_ff@(posedge clk) begin
	if(result_num[6])
		user_full <= 1;
	else
		user_full <= 0;
end

always_comb begin
	case(save_item_id)
	Small: in_1 = user.shop.small_num;
	Medium: in_1 = user.shop.medium_num;
	Large: in_1 = user.shop.large_num;
	default: in_1 = 0;
	endcase
end

always_comb begin
	if(save_item_id == Small) begin
		if(seller.shop.small_num < save_num)
			seller_not_enough = 1;
		else
			seller_not_enough = 0;
	end
	else if(save_item_id == Medium) begin
		if(seller.shop.medium_num < save_num)
			seller_not_enough = 1;
		else
			seller_not_enough = 0;
	end else if(save_item_id == Large) begin
		if(seller.shop.large_num < save_num)
			seller_not_enough = 1;
		else
			seller_not_enough = 0;
	end else
		seller_not_enough = 0;
end

always_comb begin
	case(user.shop.level)
	Platinum: buy_fee = 'd10;
	Gold:     buy_fee = 'd30;
	Silver:   buy_fee = 'd50;
	Copper:   buy_fee = 'd70;
	default:  buy_fee = 0;
	endcase
end

always_comb begin
	case(save_item_id)
	Small:   price = 'd100;
	Medium:	 price = 'd200;
	Large:   price = 'd300;
	default: price = 0;
	endcase
end

assign buy_money_needed_without_fee = (price * save_num);
assign buy_money_needed = buy_money_needed_without_fee + buy_fee;

always_comb begin
	if(buy_money_needed > user.user.money) begin
		out_of_money = 1;
	end else begin
		out_of_money = 0;
	end
end

// next user seller
always_comb begin
	if(save_item_id == Small) begin
		next_user.shop.small_num = user.shop.small_num + save_num;
		next_user.shop.medium_num = user.shop.medium_num;
		next_user.shop.large_num = user.shop.large_num;
	end else if(save_item_id == Medium) begin
		next_user.shop.small_num = user.shop.small_num;
		next_user.shop.medium_num = user.shop.medium_num + save_num;
		next_user.shop.large_num = user.shop.large_num;
	end else begin
		next_user.shop.small_num = user.shop.small_num;
		next_user.shop.medium_num = user.shop.medium_num;
		next_user.shop.large_num = user.shop.large_num + save_num;
	end
end

always_comb begin
	if(save_item_id == Small) begin
		next_seller.shop.small_num = seller.shop.small_num - save_num;
		next_seller.shop.medium_num = seller.shop.medium_num;
		next_seller.shop.large_num = seller.shop.large_num;
	end else if(save_item_id == Medium) begin
		next_seller.shop.small_num = seller.shop.small_num;
		next_seller.shop.medium_num = seller.shop.medium_num - save_num;
		next_seller.shop.large_num = seller.shop.large_num;
	end else if(save_item_id == Large)begin
		next_seller.shop.small_num = seller.shop.small_num;
		next_seller.shop.medium_num = seller.shop.medium_num;
		next_seller.shop.large_num = seller.shop.large_num - save_num;
	end else begin
		next_seller.shop.small_num = 0;
		next_seller.shop.medium_num = 0;
		next_seller.shop.large_num = 0;
	end
end

logic [16:0] next_seller_money;
assign next_seller_money = seller.user.money + buy_money_needed_without_fee;
assign next_user.user.money = user.user.money - buy_money_needed;
assign next_seller.user.money = (next_seller_money > 16'b1111111111111111) ? 16'b1111111111111111 : next_seller_money[15:0];

assign next_shop_history.item_ID = save_item_id;
assign next_shop_history.item_num = save_num;
assign next_shop_history.seller_ID = save_seller_id;

assign next_user.user.shop_history = next_shop_history;
assign next_seller.user.shop_history = seller.user.shop_history;

always_comb begin
	case(save_item_id)
	Small:   earned_exp = 'd20 * save_num;
	Medium:  earned_exp = 'd40 * save_num;
	default: earned_exp = 'd60 * save_num;
	endcase
end

logic [12:0] cal_next_exp;
assign cal_next_exp = user.shop.exp + earned_exp;

always_comb begin
	if(user.shop.level == Copper && cal_next_exp >= 'd1000) begin
		upgrade_level = 1;
		next_level = Silver;
	end
	else if(user.shop.level == Silver && cal_next_exp >= 'd2500) begin
		upgrade_level = 1;
		next_level = Gold;
	end
	else if(user.shop.level == Gold && cal_next_exp >= 'd4000) begin
		upgrade_level = 1;
		next_level = Platinum;
	end
	else begin
		upgrade_level = 0;
		next_level = user.shop.level;
	end
end

always_comb begin
	if(upgrade_level || user.shop.level == Platinum) begin
		next_exp = 0;
	end
	else if(user.shop.level == Platinum && cal_next_exp >= 'd65535) begin
		next_exp = 'd65535;
	end else
		next_exp = user.shop.exp + earned_exp;
end

assign next_user.shop.exp = next_exp;
assign next_user.shop.level = next_level;
assign next_seller.shop.exp = seller.shop.exp;
assign next_seller.shop.level = seller.shop.level;




//deposit
//logic [15:0] next_money;
//logic wallet_is_full;
always_comb begin
	next_money = user.user.money + save_amnt;
end

always_comb begin
	wallet_is_full = (current_state == S_DEPOSIT_CAL) ? (next_money > 'b1111111111111111) : 0;
end

always_comb begin
	next_deposit_user.user.money = next_money;
	next_deposit_user.shop = user.shop;
	next_deposit_user.user.shop_history = user.user.shop_history;
end

// check ----------------------------------------------------
logic [2:0] count_check;
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		count_check <= 0;
	end else if(current_state == S_CHECK_READ)
		count_check <= count_check + 1;
	else
		count_check <= 0;
end



always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		current_state <= S_IDLE;
	else
		current_state <= next_state;
end
/*
No_action	= 4'd0,
	Buy				= 4'd1,
	Check			= 4'd2,
	Deposit		= 4'd4, 
	Return		= 4'd8 
*/
/*
typedef union packed { 	
	Money					d_money;
	User_id	[1:0]	d_id;
	Action	[3:0]	d_act;
	Item_id	[7:0]	d_item;
	Item_num_ext	d_item_num;
} DATA;
*/

// check
//Record [255:0] all_record;
always_ff@(posedge clk) begin
	if(current_state == S_CHECK_READ)
		if(inf.id_valid)
			is_check_user_stock <= 0;
		else
			is_check_user_stock <= 1;
end

integer i;
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		for(i = 0;i < 256; i = i+1) begin
			all_record[i] <= 0;
		end
	end else if(current_state == S_OUT && save_complete) begin
		case(save_action)
		Is_Buy: begin
			all_record[save_seller_id].is_buy <= 0;
			all_record[save_seller_id].return_ok <= 1;
			all_record[save_seller_id].last_id <= save_user_id;
			all_record[save_user_id].is_buy <= 1;
			all_record[save_user_id].return_ok <= 0;
		end
		Is_Check: begin
		if(is_check_user_stock) begin
			all_record[save_user_id].is_buy <= 0;
			all_record[save_user_id].return_ok <= 0;
		end
		else begin
			all_record[save_user_id].is_buy <= 0;
			all_record[save_user_id].return_ok <= 0;
			all_record[save_seller_id].is_buy <= 0;
			all_record[save_seller_id].return_ok <= 0;
		end
		end
		Is_Deposit: begin
			all_record[save_user_id].is_buy <= 0;
			all_record[save_user_id].return_ok <= 0;
		end
		Is_Return: begin
			all_record[save_user_id].is_buy <= 0;
			all_record[save_user_id].return_ok <= 0;
			all_record[save_seller_id].is_buy <= 0;
			all_record[save_seller_id].return_ok <= 0;
		end
		endcase
	end
end

// return
assign wrong_operation = ( all_record[save_user_id].is_buy == 0 )||( all_record[user.user.shop_history.seller_ID].return_ok == 0 ) || (all_record[user.user.shop_history.seller_ID].last_id != save_user_id);
assign wrong_id = ( save_seller_id != user.user.shop_history.seller_ID );
assign wrong_number = (save_num != user.user.shop_history.item_num);
assign wrong_item = (save_item_id != user.user.shop_history.item_ID);

//

always_comb begin
	next_return_user.user.money = user.user.money + buy_money_needed_without_fee;
	next_return_user.user.shop_history = user.user.shop_history;
	next_return_user.shop.exp = user.shop.exp;
	next_return_user.shop.level = user.shop.level;
end

always_comb begin
	next_return_seller.user.money = seller.user.money - buy_money_needed_without_fee;
	next_return_seller.user.shop_history = seller.user.shop_history;
	next_return_seller.shop.exp = seller.shop.exp;
	next_return_seller.shop.level = seller.shop.level;
end

always_comb begin
	if(save_item_id == Small) begin
		next_return_user.shop.small_num = user.shop.small_num - save_num;
		next_return_user.shop.medium_num = user.shop.medium_num;
		next_return_user.shop.large_num = user.shop.large_num;
	end else if(save_item_id == Medium) begin
		next_return_user.shop.small_num = user.shop.small_num;
		next_return_user.shop.medium_num = user.shop.medium_num - save_num;
		next_return_user.shop.large_num = user.shop.large_num;
	end else begin
		next_return_user.shop.small_num = user.shop.small_num;
		next_return_user.shop.medium_num = user.shop.medium_num;
		next_return_user.shop.large_num = user.shop.large_num - save_num;
	end
end

always_comb begin
	if(save_item_id == Small) begin
		next_return_seller.shop.small_num = seller.shop.small_num + save_num;
		next_return_seller.shop.medium_num = seller.shop.medium_num;
		next_return_seller.shop.large_num = seller.shop.large_num;
	end else if(save_item_id == Medium) begin
		next_return_seller.shop.small_num = seller.shop.small_num;
		next_return_seller.shop.medium_num = seller.shop.medium_num + save_num;
		next_return_seller.shop.large_num = seller.shop.large_num;
	end else begin
		next_return_seller.shop.small_num = seller.shop.small_num;
		next_return_seller.shop.medium_num = seller.shop.medium_num;
		next_return_seller.shop.large_num = seller.shop.large_num + save_num;
	end
end


always_comb begin
	case(current_state)
	S_IDLE:
		if(inf.act_valid) begin
		case(inf.D.d_act[0])
		Buy:	next_state = S_BUY_READ;
		Check:	next_state = S_CHECK_READ;
		Deposit: next_state = S_DEPOSIT_READ;
		Return: next_state = S_RETURN_READ;
		default: next_state = S_IDLE;
		endcase
		end
		else
			next_state = S_IDLE;
	// Buy
	S_BUY_READ:
		if(inf.id_valid && user_info_valid)
			next_state = S_BUY_GET_SELLER_REQUEST;
		else if(inf.id_valid)
			next_state = S_BUY_READ_WAIT;
		else
			next_state = S_BUY_READ;
	S_BUY_READ_WAIT:
		if(user_info_valid)
			next_state = S_BUY_GET_SELLER_REQUEST;
		else
			next_state = S_BUY_READ_WAIT;
	S_BUY_GET_SELLER_REQUEST:
		next_state = S_BUY_GET_SELLER_WAIT;
	S_BUY_GET_SELLER_WAIT:
		if(inf.C_out_valid)
			next_state = S_BUY_CAL;
		else
			next_state = S_BUY_GET_SELLER_WAIT;
	S_BUY_CAL:
		if(buy_success)
			next_state = S_WRITE_SELLER_REQUEST;
		else
			next_state = S_OUT;
	// check
	S_CHECK_READ:
		if(inf.id_valid && user_info_valid)
			next_state = S_CHECK_REQUEST;
		else if(inf.id_valid)
			next_state = S_CHECK_WAIT;
		else if(count_check == 'd5 && user_info_valid) // ----------------------------------------------------------------------------------------------------
			next_state = S_OUT;
		else if(count_check == 'd5)
			next_state = S_CHECK_WAIT_2;
		else
			next_state = S_CHECK_READ;
	S_CHECK_WAIT_2:
		if(inf.C_out_valid)
			next_state = S_OUT;
		else
			next_state = S_CHECK_WAIT_2;
	S_CHECK_WAIT:
		if(inf.C_out_valid)
			next_state = S_CHECK_REQUEST;
		else
			next_state = S_CHECK_WAIT;
	S_CHECK_REQUEST:
		next_state = S_CHECK_REQUEST_WAIT;
	S_CHECK_REQUEST_WAIT:
		if(inf.C_out_valid)
			next_state = S_OUT;
		else
			next_state = S_CHECK_REQUEST_WAIT;
	// deposit
	S_DEPOSIT_READ:
		if(inf.amnt_valid && user_info_valid)
			next_state = S_DEPOSIT_CAL;
		else if(inf.amnt_valid)
			next_state = S_DEPOSIT_WAIT;
		else
			next_state = S_DEPOSIT_READ;
	S_DEPOSIT_WAIT:
		if(inf.C_out_valid)
			next_state = S_DEPOSIT_CAL;
		else
			next_state = S_DEPOSIT_WAIT;
	S_DEPOSIT_CAL:
		if(!wallet_is_full)
			next_state = S_WRITE_USER_REQUEST;
		else
			next_state = S_OUT;
			
	// Return
	S_RETURN_READ:
		if(inf.id_valid && user_info_valid)
			next_state = S_RETURN_JUDGE;
		else if(inf.id_valid)
			next_state = S_RETURN_READ_WAIT;
		else
			next_state = S_RETURN_READ;
	S_RETURN_READ_WAIT:
		if(user_info_valid)
			next_state = S_RETURN_JUDGE;
		else
			next_state = S_RETURN_READ_WAIT;
	S_RETURN_JUDGE:
		if(return_success)
			next_state = S_RETURN_GET_SELLER_REQUEST;
		else
			next_state = S_OUT;
	S_RETURN_GET_SELLER_REQUEST:
		next_state = S_RETURN_GET_SELLER_WAIT;
	S_RETURN_GET_SELLER_WAIT:
		if(inf.C_out_valid)
			next_state = S_RETURN_CAL;
		else
			next_state = S_RETURN_GET_SELLER_WAIT;
	S_RETURN_CAL:
		next_state = S_WRITE_SELLER_REQUEST;
	// write back
	S_WRITE_SELLER_REQUEST:
		next_state = S_WRITE_SELLER_WAIT;
	S_WRITE_SELLER_WAIT:
		if(inf.C_out_valid)
			next_state = S_WRITE_USER_REQUEST;
		else
			next_state = S_WRITE_SELLER_WAIT;
	S_WRITE_USER_REQUEST:
		next_state = S_WRITE_USER_WAIT;
	S_WRITE_USER_WAIT:
		if(inf.C_out_valid)
			next_state = S_OUT;
		else
			next_state = S_WRITE_USER_WAIT;
	default: next_state = S_IDLE;
	endcase
end

//output save

always_ff @(posedge clk) begin
	case(current_state)
	S_BUY_CAL:
		save_out_info <= next_user.user;
	S_DEPOSIT_CAL:
		save_out_info <= {16'd0,next_money};
	S_CHECK_WAIT_2, S_CHECK_READ:
		if(save_user_info_valid)
			save_out_info <= {16'd0,user.user.money};
		else
			save_out_info <= {16'd0,d_out.user.money};
	S_CHECK_REQUEST_WAIT:
		save_out_info <= {14'd0,d_out.shop.large_num,d_out.shop.medium_num,d_out.shop.small_num};
	S_RETURN_CAL:
		save_out_info <= {14'd0,next_return_user.shop.large_num,next_return_user.shop.medium_num,next_return_user.shop.small_num};
	default: save_out_info <= save_out_info;
	endcase
end

always_ff @(posedge clk) begin
	case(current_state)
	S_BUY_CAL:
		if(user_full)
			save_err <= iNV_Full;
		else if(seller_not_enough)
			save_err <= iNV_Not_Enough;
		else if(out_of_money)
			save_err <= out_of_Money;
		else
			save_err <= no_Err;
	S_DEPOSIT_CAL:
		if(wallet_is_full)
			save_err <= wallet_is_Full;
		else
			save_err <= no_Err;
	S_CHECK_READ:
		save_err <= no_Err;
	S_RETURN_JUDGE:
		if(wrong_operation)
			save_err <= wrong_act;
		else if(wrong_id)
			save_err <= wrong_ID;
		else if(wrong_number)
			save_err <= wrong_Num;
		else if(wrong_item)
			save_err <= wrong_Item;
		else
			save_err <= no_Err;
	default: save_err <= save_err;
	endcase
end

always_ff @(posedge clk) begin
	case(current_state)
	S_BUY_CAL:
		save_complete <= buy_success;
	S_DEPOSIT_CAL:
		save_complete <= !wallet_is_full;
	S_CHECK_READ:
		save_complete <= 1;
	S_RETURN_JUDGE:
		save_complete <= return_success;
	default: save_complete <= save_complete;
	endcase
end

//out_valid, err_msg,  complete, out_info, 
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.out_valid <= 0;
	else if(current_state == S_OUT)
		inf.out_valid <= 1;
	else
		inf.out_valid <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.err_msg <= No_Err;
	else if(current_state == S_OUT)
		inf.err_msg <= save_err;
	else
		inf.err_msg <= No_Err;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.complete <= 0;
	else if(current_state == S_OUT)
		inf.complete <= save_complete;
	else
		inf.complete <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.out_info <= 0;
	else if(current_state == S_OUT && save_complete)
		inf.out_info <= save_out_info;
	else
		inf.out_info <= 0;
end

endmodule