// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library Comparators {
    function less(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function greater(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }
}
