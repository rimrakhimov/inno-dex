// SPDX-License-Identifier: MIT

import "../ERC20.sol";
import "../../utils/Context.sol";

pragma solidity ^0.8.3;

contract ERC20Mintable is Context, ERC20 {
    uint256 public constant distanceLimit = 30;

    event Granted(address indexed receiver, uint256 tokens);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function requestTokens(uint256 distance) public returns (bool) {
        require(distance <= distanceLimit, "Too far away");
        uint256 toMint = 1;

        _mint(_msgSender(), toMint);
        emit Granted(_msgSender(), toMint);

        return true;
    }
}
