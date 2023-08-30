//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Optimum Application-Specific Integrated System Laboratory
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Spring
//   Lab09  : Online Shopping Platform Simulation
//   Author : Zhi-Ting Dong (yjdzt918.ee11@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Usertype_OS.sv
//   Module Name : usertype
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic [3:0] { 
	No_action	= 4'd0,
	Buy				= 4'd1,
	Check			= 4'd2,
	Deposit		= 4'd4, 
	Return		= 4'd8 
}	Action ;

typedef enum logic [3:0] { 
	No_Err					= 4'b0000, //	No error
	INV_Not_Enough	= 4'b0010, //	Seller's inventory is not enough
	Out_of_money		= 4'b0011, //	Out of money
	INV_Full				= 4'b0100, //	User's inventory is full 
	Wallet_is_Full	= 4'b1000, //	Wallet is full
	Wrong_ID				= 4'b1001, //	Wrong seller ID 
	Wrong_Num				= 4'b1100, //	Wrong number
	Wrong_Item			= 4'b1010, //	Wrong item
	Wrong_act				= 4'b1111  //	Wrong operation
}	Error_Msg ;

typedef enum logic [1:0]	{ 
	Platinum	= 2'b00,
	Gold			= 2'b01,
	Silver		= 2'b10,
	Copper		= 2'b11
}	User_Level ;				

typedef enum logic [1:0] {
	No_item	= 2'd0,
	Large		= 2'd1,
	Medium	= 2'd2,
	Small		= 2'd3
}	Item_id ;


typedef logic [7:0] User_id;
typedef logic [5:0] Item_num;
typedef logic [15:0] Money;
typedef logic [11:0] EXP;
typedef logic [15:0] Item_num_ext;

typedef struct packed {
	Item_id		item_ID;
	Item_num	item_num;
	User_id		seller_ID;
}	Shopping_His; // Shopping History

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

typedef union packed { 	
	Money					d_money;
	User_id	[1:0]	d_id;
	Action	[3:0]	d_act;
	Item_id	[7:0]	d_item;
	Item_num_ext	d_item_num;
} DATA;

//################################################## Don't revise the code above

//#################################
// Type your user define type here
//#################################
typedef logic [7:0] each_hex;
typedef logic Flag;
typedef enum logic [4:0] {
	S_IDLE,
	S_BUY_CAL,
	S_BUY_READ,
	S_BUY_READ_WAIT,
	S_BUY_GET_SELLER_REQUEST,
	S_BUY_GET_SELLER_WAIT,
	S_CHECK_READ,
	S_CHECK_WAIT,
	S_CHECK_WAIT_2,
	S_CHECK_REQUEST,
	S_CHECK_REQUEST_WAIT,
	S_DEPOSIT_READ,
	S_DEPOSIT_WAIT,
	S_DEPOSIT_CAL,
	S_DEPOSIT_OUT,
	S_RETURN_READ,
	S_RETURN_READ_WAIT,
	S_RETURN_JUDGE,
	S_RETURN_GET_SELLER_WAIT,
	S_RETURN_GET_SELLER_REQUEST,
	S_RETURN_CAL,
	S_WRITE_SELLER_REQUEST,
	S_WRITE_SELLER_WAIT,
	S_WRITE_USER_REQUEST,
	S_WRITE_USER_WAIT,
	S_OUT
}	State;

typedef union packed {
	each_hex [0:7] e;
}	Dram_out_change_format;

typedef struct packed {
	User_Info user;
	Shop_Info shop;
}	Person_info;

typedef struct packed {
	User_Level	level;
	EXP					exp;
	Item_num		large_num;
	Item_num		medium_num;
	Item_num		small_num;
}	My_Shop_Info; //Shop info

typedef union packed {
	User_Info user_info;
	Money [1:0] money;
	My_Shop_Info stock;
}	out_format;

typedef struct packed {
	User_id	last_id;
	Flag is_buy;
	Flag return_ok;
}	Record; //Shop info

typedef enum logic [1:0] {
	Is_Buy,
	Is_Check,
	Is_Deposit,
	Is_Return
}	My_action;

typedef enum logic [3:0] { 
	no_Err					= 4'b0000, //	No error
	iNV_Not_Enough	= 4'b0010, //	Seller's inventory is not enough
	out_of_Money		= 4'b0011, //	Out of money
	iNV_Full				= 4'b0100, //	User's inventory is full 
	wallet_is_Full	= 4'b1000, //	Wallet is full
	wrong_ID				= 4'b1001, //	Wrong seller ID 
	wrong_Num				= 4'b1100, //	Wrong number
	wrong_Item			= 4'b1010, //	Wrong item
	wrong_act				= 4'b1111  //	Wrong operation
}	Err_Msg ;



//################################################## Don't revise the code below
endpackage
import usertype::*; //import usertype into $unit

`endif

