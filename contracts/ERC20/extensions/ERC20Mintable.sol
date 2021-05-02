// SPDX-License-Identifier: MIT

import "../ERC20.sol";
import "../../utils/Context.sol";
import "../../utils/Ownable.sol";

pragma solidity ^0.8.3;

contract ERC20Mintable is Context, Ownable, ERC20 {
    uint256 public constant fee = 343 * 10**12;
    uint256 public constant minimalDistance = 30;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    event Granted(address indexed receiver, uint256 tokens);
    event Withdraw(address indexed owner, uint256 fee);

    function requestTokens(uint256 distance) public returns (bool) {
        require(distance < minimalDistance);

        uint256 toMint = 1;

        _mint(_msgSender(), toMint);
        emit Granted(_msgSender(), toMint);

        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        uint256 to_withdraw = address(this).balance;

        payable(owner()).transfer(to_withdraw);
        emit Withdraw(owner(), to_withdraw);
        return true;
    }
}
