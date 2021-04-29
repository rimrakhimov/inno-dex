// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract OrderBook {
    enum OrderType {Buy, Sell}

    struct Order {
        bytes32 id;
        address instrument;
        OrderType orderType;
        uint256 price;
        uint256 qty;
    }

    struct OrderBookQty {
        uint256 price;
        uint256 qty;
    }

    mapping(uint256 => Order[]) bids;
    mapping(uint256 => Order[]) asks;

    uint256[] sortedBidPrices;
    uint256[] sortedAskPrices;

    // mapping(bytes32 => uint256) orderIndexByOrderId;

    function addBid(Order memory order) external {
        assert(order.orderType == OrderType.Sell);

        uint256 price = order.price;

        Order[] storage orders = bids[price];
        if (orders.length == 0) {   // no orders with the price existed in order book before
            insertIntoSortedArray(sortedBidPrices, price, 0);
        }
        orders.push(order);
    }

    function addAsk(Order memory order) external {
        assert(order.orderType == OrderType.Buy);

        uint256 price = order.price;

        Order[] storage orders = asks[price];
        if (orders.length == 0) {   // no orders with the price existed in order book before
            insertIntoSortedArray(sortedAskPrices, price, 0);
        }
        orders.push(order);
    }

    function addToOrderBook(Order memory order) external {
        
    }

    // TODO: use binary search to increase performance
    function insertIntoSortedArray(
        uint256[] storage arr,
        uint256 val,
        uint256 index
    ) private {
        // there is no more elements in the array to process
        if (arr.length == index) {
            arr.push(val);
            return;
        }

        if (arr[index] < val) {
            insertIntoSortedArray(arr, val, index + 1);
        } else {
            shiftElements(arr, index);
            arr[index] = val;
        }
    }

    function shiftElements(uint256[] storage arr, uint256 startingIndex)
        private
    {
        uint256 index = arr.length - 1;

        arr.push(arr[index]); // copy last element to new cell

        while (index > startingIndex) {
            arr[index] = arr[index - 1];
            index -= 1;
        }
    }
}
