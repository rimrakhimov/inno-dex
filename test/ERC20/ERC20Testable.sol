pragma solidity ^0.8.3;

import "../../contracts/ERC20/ERC20.sol";
import "../../contracts/utils/Context.sol";

contract ERC20Testable is Context, ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    event Granted(address indexed receiver, uint256 tokens);

    function requestTokens(uint256 toMint) public returns (bool) {
        _mint(_msgSender(), toMint);
        emit Granted(_msgSender(), toMint);

        return true;
    }
}
