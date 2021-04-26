// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract ERC20Basic {

	string public name;
	string public symbol;
	uint8 public constant decimals = 18;

	uint public constant fee = 343 * 10**12;
	uint public constant minimalDistance = 30;


	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Transfer(address indexed from, address indexed to, uint tokens);

	event Granted(address indexed receiver, uint tokens);
	event Withdraw(address indexed owner, uint fee);


	mapping(address => uint256) balances;

	mapping(address => mapping (address => uint256)) allowed;

	uint256 totalSupply_;
	address owner_;

	using SafeMath for uint256;


   constructor(string memory _name, string memory _symbol, uint256 total) {
        name = _name;
        symbol = _symbol;
        totalSupply_ = total;
        balances[address(this)] = totalSupply_;
        owner_ = msg.sender;
	}

	function totalSupply() public view returns (uint256) {
        return totalSupply_;
	}

	function faucetSupply() public view returns (uint256) {
	    return balances[address(this)];
	}

	function balanceOf(address tokenOwner) public view returns (uint) {
    	return balances[tokenOwner];
	}

	function transfer(address receiver, uint numTokens) public payable returns (bool) {
	    require(msg.value >= fee);
    	require(numTokens <= balances[msg.sender]);
    	balances[msg.sender] = balances[msg.sender].sub(numTokens);
    	balances[receiver] = balances[receiver].add(numTokens);

    	uint remainder = msg.value.sub(fee);
    	payable(msg.sender).transfer(remainder);

    	emit Transfer(msg.sender, receiver, numTokens);
    	return true;
	}

	function requestTokens(uint distance) public returns (bool) {
	    require(distance < minimalDistance);
	    require(faucetSupply() >= 1);

	    balances[address(this)] = balances[address(this)].sub(1);
	    balances[msg.sender] = balances[msg.sender].add(1);
	    emit Granted(msg.sender, 1);
	    return true;

	}

	function withdraw() public returns (bool) {
	    require(msg.sender == owner_);

	    uint to_withdraw = address(this).balance;

	    payable(owner_).transfer(to_withdraw);
	    emit Withdraw(owner_, to_withdraw);
	    return true;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  	assert(b <= a);
  	return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a + b;
  	assert(c >= a);
  	return c;
	}
}