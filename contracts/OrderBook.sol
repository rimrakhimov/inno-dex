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
    }

    // function getSortedPrices() external view returns (uint256[] memory) {
    //     return ordersByPrice.getSortedKeys();
    // }

    function empty() public view returns (bool) {
        return ordersByPrice.empty();
    }

    function getSpotPrice() public view returns (uint256) {
        return ordersByPrice.getSortedKeys()[0];
    }

    // function getOrdersByPrice(uint256 price) external view returns (Order[] memory) {
    //     return ordersByPrice.get(price).toStorageArray();
    // }

    function getNextOrder() external view returns (Order memory) {
        return ordersByPrice.get(getSpotPrice()).toStorageArray()[0];
    }

    function add(Order memory order) external {
        orderIdToPrice[order.id] = order.price;
        ordersByPrice.insert(order, _isDescending());
    }

    function remove(bytes32 orderId) external {
        uint256 price = orderIdToPrice[orderId];
        ordersByPrice.remove(orderId, price);

        delete orderIdToPrice[orderId];
    }

    function _isDescending() private view returns (bool) {
        return _orderBookType == OrderType.Sell;
    }

    // function decreaseQuantity(bytes32 orderId, uint256 qty) external {

    // }
}
