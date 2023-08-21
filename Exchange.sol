// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./Token.sol";


contract Exchange {
	address public feeAccount;
	uint256 public feePercent;
	mapping(address => mapping(address=> uint256)) public tokens;
	mapping(uint256 => _Order) public orders;
	uint256 public orderCount;
	mapping(uint256 => bool) public orderCancelled; //true or false
	mapping(uint256 => bool) public orderFilled; //true or false

	event Deposit(
		address token,
		 address user,
		  uint256 amount,
		   uint256 balance
		   );

	event Withdraw(
	 address token,
	  address user,
	   uint256 amount,
	    uint256 balance
	    );


	event Order( //underscore is to differ naming event
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		uint256 timestamp
		);

	event Cancel(
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		uint256 timestamp
		);

	event Trade (
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		address creator,
		uint256 timestamp
		);

	//way to model the order
	struct _Order {
		// attributes of an order
		uint256 id; //unique identifier
		address user; //user who made the user
		address tokenGet;		//address of the token they receive
		uint256 amountGet;		//amount they receive
		address tokenGive;		//amount of token they give
		uint256 amountGive;		//amount they give
		uint256 timestamp; 	//when order was created

	}


	constructor(address _feeAccount, uint256 _feePercent){
		feePercent = _feePercent;
		feeAccount = _feeAccount;
	}

	//DEPOSIT AND WITHDRAW
	function depositToken(address _token, uint256 _amount) public{
		//transfer tokens to exchange

		require(Token(_token).transferFrom(msg.sender, address(this),_amount));

		//update balance
		tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;

		//emit event
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);			
			}
	function withdrawToken(address _token, uint256 _amount) public {
				//ensure user has enough tokens to withdraw
				require(tokens[_token][msg.sender]>= _amount);
				//transfer tokens to the user
				Token(_token).transfer(msg.sender, _amount);

				//update user balance
		tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;

				//emit an event
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
			}

	function balanceOf(address _token, address _user)
		public
		view
		returns (uint256)
		{
		return tokens[_token][_user];
		}



// make and cancel orders


	function makeOrder(
		address _tokenGet,
		uint256 _amountGet,
		 address _tokenGive,
		  uint256 _amountGive
	) public {

		require(balanceOf(_tokenGive, msg.sender) >= _amountGive); //prevent sorders if tokens arent on the exchange
		//require token balance
				//creates order
		orderCount++;
		orders[orderCount] = _Order(
			orderCount,
			msg.sender, //0x...
			_tokenGet,//tokenGet
			_amountGet,
			_tokenGive,
			_amountGive,
			block.timestamp //timestamp 1893507958secs


			);

		//emit event
		emit Order(
			orderCount,
			msg.sender, //0x...
			_tokenGet,//tokenGet
			_amountGet,
			_tokenGive,
			_amountGive,
			block.timestamp
		);
	}

	function cancelOrder(uint256 _id) public {
		  // Fetch order
        _Order storage _order = orders[_id];

        // Ensure the caller of the function is the owner of the order
        require(address(_order.user) == msg.sender);

        // Order must exist
        require(_order.id == _id);

        // Cancel the order
        orderCancelled[_id] = true;

		//Emit event
		emit Cancel(
			orderCount,
			msg.sender, //0x...
			_order.tokenGet,//tokenGet
			_order.amountGet,
			_order.tokenGive,
			_order.amountGive,
			block.timestamp
		);

	}

	//executing orders-------------------
	function fillOrder(uint256 _id) public {
		//must be a valid orderId
		require(_id> 0 && _id <= orderCount, "Order does not exist");
		//order cant be filled
		require(!orderFilled[_id]);
		//order cant be cancelled

		require(!orderCancelled[_id]);




		//fetch order
		_Order storage _order = orders[_id];

		//swapping tokens(trading)
			_trade(
				_order.id,
			 	_order.user,
			 	_order.tokenGet,
			 	_order.amountGet,
			 	_order.tokenGive,
			 	_order.amountGive
			 );
					//marks order as filled
			orderFilled[_order.id] = true;
	}

	function _trade(
		uint256 _orderId,
		address _user,
		address _tokenGet,
		uint256 _amountGet,
		address _tokenGive,
		uint256 _amountGive

		) internal {

		//Fee is payed by the person making the order
		//fee is deducted from _amountGet
		uint256 _feeAmount = (_amountGet * feePercent) / 100;


			//execute trade
		//do trade here..... msg.sender is the user who filled the order, while _user is who created the order
		tokens[_tokenGet][msg.sender] =  
		tokens [_tokenGet][msg.sender] - 
		(_amountGet + _feeAmount);

		tokens[_tokenGet][_user] =
		 tokens[_tokenGet][_user] +
		  _amountGet;

		//chrage fees
		tokens[_tokenGet][feeAccount] =
		 tokens[_tokenGet][feeAccount] +
		  _feeAmount; 

		tokens[_tokenGive][_user] =
		 tokens[_tokenGive][_user] -
		  _amountGive;
		tokens[_tokenGive][msg.sender] = 
		tokens[_tokenGive][msg.sender] +
		 _amountGive;

		 emit Trade(
		 	_orderId,
		 	msg.sender,
		 	_tokenGet,
		 	_amountGet,
		 	_tokenGive,
		 	_amountGive,
		 	_user,
		 	block.timestamp

		 	);
	} 
}