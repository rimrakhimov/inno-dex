// SPDX-License-Identifier: MIT

import "./libraries/SharedOrderStructs.sol";
import "./libraries/OrderSet.sol";
import "./libraries/IterableUintToOrderSetMapping.sol";
import "./utils/Ownable.sol";

pragma solidity ^0.8.3;

contract OrderBook is Ownable {
    using OrderSetLib for OrderSet;
    using IterableUintToOrderSetMapping for IterableUintToOrderSetMapping.Mapping;

    IterableUintToOrderSetMapping.Mapping ordersByPrice;

    mapping(bytes32 => uint256) orderIdToPrice;

    OrderType _orderBookType;

    constructor(OrderType orderBookType) {
        _orderBookType = orderBookType;
        ordersByPrice.comparator = _getComparator(_isDescending());
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        return ordersByPrice.get(orderIdToPrice[orderId]).get(orderId);
    }

    function getOrderBookQtys() external view returns (OrderBookQty[] memory) {
        uint256 size = ordersByPrice.size();
        OrderBookQty[] memory result = new OrderBookQty[](size);

        uint256[] memory prices = ordersByPrice.getSortedKeys();
        for (uint256 i = 0; i < size; i++) {
            uint256 price = prices[i];
            Order[] storage orders = ordersByPrice.get(price).toStorageArray();
            uint256 qty = 0;
            for (uint256 j = 0; j < orders.length; j++) {
                qty += orders[j].qty;
            }
            result[i] = OrderBookQty(price, qty);
        }

        return result;
    }

    // function getSortedPrices() external view returns (uint256[] memory) {
    //     return ordersByPrice.getSortedKeys();
    // }

    function empty() public view returns (bool) {
        return ordersByPrice.empty();
    }

    function getSpotPrice() public view returns (uint256) {
        return ordersByPrice.getSortedKeys()[ordersByPrice.size() - 1];
    }

    // function getOrdersByPrice(uint256 price) external view returns (Order[] memory) {
    //     return ordersByPrice.get(price).toStorageArray();
    // }

    function getNextOrder() external view returns (Order memory) {
        return ordersByPrice.get(getSpotPrice()).toStorageArray()[0];
    }

    function add(Order memory order) external {
        orderIdToPrice[order.id] = order.price;
        ordersByPrice.insert(order);
    }

    function remove(bytes32 orderId) external {
        uint256 price = orderIdToPrice[orderId];
        ordersByPrice.remove(price, orderId);

        delete orderIdToPrice[orderId];
    }

    function _getComparator(bool isDescending)
        private
        pure
        returns (function(uint256, uint256) internal pure returns (bool) f)
    {
        return isDescending ? _greater : _less;
    }

    function _less(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function _greater(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }

    function _isDescending() private view returns (bool) {
        return _orderBookType == OrderType.Sell;
    }
}
