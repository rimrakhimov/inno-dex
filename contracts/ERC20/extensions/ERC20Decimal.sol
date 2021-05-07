// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../ERC20.sol";

abstract contract ERC20Decimal is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
