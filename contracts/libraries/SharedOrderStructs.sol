// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

enum OrderType {Buy, Sell}

struct Order {
    bytes32 id;
    uint256 price;
    uint256 qty;
    address bidder;
    OrderType orderType;
}

struct OrderBookRecord {
    uint256 price;
    uint256 qty;
    OrderType orderType;
}

library OrderLib {
    function copyFromMemory(Order storage self, Order memory mOrder) internal {
        self.id = mOrder.id;
        self.price = mOrder.price;
        self.qty = mOrder.qty;
        self.bidder = mOrder.bidder;
        self.orderType = mOrder.orderType;
    }
}
