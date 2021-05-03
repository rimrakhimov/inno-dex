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

struct OrderBookQty {
    uint256 price;
    uint256 qty;
}

library OrderLib {
    function copyFromMemory(Order storage self, Order memory mOrder) internal {
        self.id = mOrder.id;
        self.price = mOrder.price;
        self.qty = mOrder.qty;
        self.bidder = mOrder.bidder;
        self.orderType = mOrder.orderType;
    }

    function copyToMemory(Order storage self)
        internal
        view
        returns (Order memory)
    {
        Order memory order =
            Order(self.id, self.price, self.qty, self.bidder, self.orderType);
        return order;
    }

    function equal(Order memory self, Order memory another)
        internal
        pure
        returns (bool)
    {
        return
            self.id == another.id &&
            self.price == another.price &&
            self.qty == another.qty &&
            self.bidder == another.bidder &&
            self.orderType == another.orderType;
    }
}
