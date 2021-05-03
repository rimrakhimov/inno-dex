// SPDX-License-Identifier: MIT

import "../ERC20.sol";
import "../../utils/Context.sol";

pragma solidity ^0.8.3;

contract ERC20Mintable is Context, ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    event Granted(address indexed receiver, uint256 tokens);

    function requestTokens() public returns (bool) {
        uint256 toMint = 1;

        _mint(_msgSender(), toMint);
        emit Granted(_msgSender(), toMint);

        return true;
    }
}
