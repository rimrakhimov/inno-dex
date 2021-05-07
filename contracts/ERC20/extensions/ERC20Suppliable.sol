// SPDX-License-Identifier: MIT

import "../ERC20.sol";
import "./ERC20Decimal.sol";
import "../../utils/Context.sol";

pragma solidity ^0.8.3;

contract ERC20Suppliable is Context, ERC20Decimal {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) ERC20Decimal(name_, symbol_, decimals_) {
        _mint(_msgSender(), totalSupply_);
    }
}
