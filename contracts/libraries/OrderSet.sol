// SPDX-License-Identifier: MIT

import "./SharedOrderStructs.sol";

pragma solidity ^0.8.3;

struct OrderSet {
    Order[] orders;
    mapping(bytes32 => uint256) indexOf;
}

library OrderSetLib {
    using OrderLib for Order;

    function size(OrderSet storage self) internal view returns (uint256) {
        return self.orders.length;
    }

    // Returns `true` if set does not contain any element, or `false` otherwise.
    function empty(OrderSet storage self) internal view returns (bool) {
        return size(self) == 0;
    }

    // Check whether an order with \a orderId exists in the set.
    function member(OrderSet storage self, bytes32 orderId)
        internal
        view
        returns (bool)
    {
        return self.indexOf[orderId] > 0;
    }

    // Returns the order with specified \a orderId.
    // Reverts if the order does not exists in the set.
    function get(OrderSet storage self, bytes32 orderId)
        internal
        view
        returns (Order memory)
    {
        require(member(self, orderId), "Order is not in the set");

        uint256 index = self.indexOf[orderId];
        return self.orders[index - 1].copyToMemory();
    }

    // Returns array of orders from the OrderSet.
    function toStorageArray(OrderSet storage self)
        internal
        view
        returns (Order[] storage)
    {
        return self.orders;
    }

    // Adds an order to the set. Two orders are compared based on their ids.
    // If two orders have the same id, they are considered to be the same order for the set.
    // If an order already exists in the set, it is updated and `true` is returned.
    // Otherwise, a new order is added to the set and `false` is returned.
    function insert(OrderSet storage self, Order memory elem)
        internal
        returns (bool replaced)
    {
        if (!member(self, elem.id)) {
            self.orders.push(elem);

            uint256 index = self.orders.length;
            self.indexOf[elem.id] = index;
        } else {
            uint256 index = self.indexOf[elem.id];
            self.orders[index - 1].copyFromMemory(elem);

            replaced = true;
        }
    }

    // Removes order with \a orderId from the set, if such order exists.
    // If specified order does not exist returns `false`, otherwise returns `true`.
    // Does not preserve order of orders, as a last order takes place of the order to be removed.
    function remove(OrderSet storage self, bytes32 orderId)
        internal
        returns (bool removed)
    {
        if (member(self, orderId)) {
            uint256 index = self.indexOf[orderId];
            uint256 lastIndex = self.orders.length;

            Order storage lastOrder = self.orders[lastIndex - 1];
            self.indexOf[lastOrder.id] = index;
            delete self.indexOf[orderId];

            self.orders[index - 1] = lastOrder;
            self.orders.pop();

            removed = true;
        }
    }

    function clear(OrderSet storage self) internal {
        uint256 setSize = self.orders.length;
        while (setSize > 0) {
            bytes32 orderId = self.orders[setSize - 1].id;
            delete self.indexOf[orderId];
            self.orders.pop();

            setSize--;
        }
    }
}
