// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../utils/Ownable.sol";
import "../libraries/Bytes32Set.sol";
import "../libraries/IterableSortedUintToBytes32SetMapping.sol";
import "../libraries/Comparators.sol";
import "../libraries/SharedOrderStructs.sol";
import "../utils/Ownable.sol";

contract OrderBook is Ownable {
    using OrderLib for Order;
    using Bytes32SetLib for Bytes32Set;
    using IterableSortedUintToBytes32SetMapping for IterableSortedUintToBytes32SetMapping.Mapping;

    mapping(bytes32 => Order) _orderIdToOrder;
    IterableSortedUintToBytes32SetMapping.Mapping _orderIdsByPrice;

    OrderType _orderBookType;

    constructor(OrderType orderBookType) {
        _orderBookType = orderBookType;
        _orderIdsByPrice.desc = _isDescending();
    }

    function getOrderBookType() external view returns (OrderType) {
        return _orderBookType;
    }

    function empty() public view returns (bool) {
        return _orderIdsByPrice.empty();
    }

    function member(bytes32 orderId) public view returns (bool) {
        return _orderIdToOrder[orderId].id == orderId;
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        require(
            member(orderId),
            "Specified order is not located in the order book"
        );
        return _orderIdToOrder[orderId];
    }

    function getOrderBookRecords(bool desc)
        external
        view
        returns (OrderBookRecord[] memory)
    {
        uint256 size = _orderIdsByPrice.size();
        OrderBookRecord[] memory result = new OrderBookRecord[](size);

        uint256[] memory prices = _orderIdsByPrice.getSortedKeys();
        for (uint256 i = 0; i < size; i++) {
            uint256 price = prices[i];
            bytes32[] storage orderIds =
                _orderIdsByPrice.get(price).toStorageArray();
            uint256 totalQty = 0;
            for (uint256 j = 0; j < orderIds.length; j++) {
                totalQty += _orderIdToOrder[orderIds[j]].qty;
            }
            result[i] = OrderBookRecord(price, totalQty, _orderBookType);
        }

        return (_isDescending() == desc) ? result : _reverseArray(result);
    }

    function getSpotPrice() public view returns (uint256) {
        require(!empty(), "Order book is empty");
        return _orderIdsByPrice.getSortedKeys()[_orderIdsByPrice.size() - 1];
    }

    function getNextOrder() external view returns (Order memory) {
        require(!empty(), "Order book is empty");
        bytes32 orderId = _orderIdsByPrice.get(getSpotPrice()).any();
        return _orderIdToOrder[orderId];
    }

    function add(Order memory order)
        external
        onlyOwner
        returns (bool modified)
    {
        require(
            order.orderType == _orderBookType,
            "Order type does not correspond to order book type"
        );
        if (member(order.id)) {
            require(
                order.price == _orderIdToOrder[order.id].price,
                "Order price cannot be changed"
            );
            modified = true;
        } else {
            uint256 price = order.price;
            if (!_orderIdsByPrice.member(price)) {
                _orderIdsByPrice.addKey(price);
            }
            Bytes32Set storage priceOrderIds = _orderIdsByPrice.get(price);
            priceOrderIds.insert(order.id);
        }
        _orderIdToOrder[order.id].copyFromMemory(order);
    }

    function remove(bytes32 orderId) external onlyOwner returns (bool removed) {
        if (member(orderId)) {
            uint256 price = _orderIdToOrder[orderId].price;
            delete _orderIdToOrder[orderId];

            Bytes32Set storage priceOrderIds = _orderIdsByPrice.get(price);
            priceOrderIds.remove(orderId);

            if (priceOrderIds.empty()) {
                _orderIdsByPrice.removeKey(price);
            }

            removed = true;
        }
    }

    /******************************** internal ********************************/

    function _isDescending() internal view returns (bool) {
        return (_orderBookType == OrderType.Sell);
    }

    function _reverseArray(OrderBookRecord[] memory array)
        private
        pure
        returns (OrderBookRecord[] memory)
    {
        uint256 size = array.length;
        OrderBookRecord[] memory result = new OrderBookRecord[](size);

        for (uint256 i = 0; i < size; i++) {
            result[i] = array[size - i - 1];
        }
        return result;
    }
}
