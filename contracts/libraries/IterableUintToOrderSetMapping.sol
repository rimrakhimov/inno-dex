// SPDX-License-Identifier: MIT

import "./SharedOrderStructs.sol";
import "./OrderSet.sol";

pragma solidity ^0.8.3;

library IterableUintToOrderSetMapping {
    using OrderSetLib for OrderSet;

    struct Mapping {
        uint256[] keys;
        mapping(uint256 => OrderSet) values;
        mapping(uint256 => uint256) indexOf;
    }

    function member(Mapping storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.values[key].empty();
    }

    function size(Mapping storage self) internal view returns (uint256) {
        return self.keys.length;
    }

    function empty(Mapping storage self) internal view returns (bool) {
        return size(self) == 0;
    }

    function get(Mapping storage self, uint256 key)
        internal
        view
        returns (OrderSet storage)
    {
        require(member(self, key), "Key does not exist");
        return self.values[key];
    }

    // function getKeys(Mapping storage self)
    //     internal
    //     view
    //     returns (uint256[] memory)
    // {
    //     return self.keys;

    // }

    function getSortedKeys(Mapping storage self)
        internal
        view
        returns (uint256[] memory)
    {
        return self.keys;
    }

    function insert(
        Mapping storage self,
        Order memory order,
        bool desc
    ) internal returns (bool replaced) {
        uint256 key = order.price;
        if (self.values[key].member(order.id)) {
            self.values[key].insert(order);
            replaced = true;
        } else if (member(self, key)) {
            self.values[key].insert(order);
        } else {
            self.values[key].insert(order);
            insertKey(self, key, 0);
        }
    }

    function remove(
        Mapping storage self,
        bytes32 orderId,
        uint256 price
    ) internal returns (bool removed) {
        if (self.values[price].member(orderId)) {
            self.values[price].remove(orderId);

            if (!member(self, price)) {
                removeKey(self, price);
            }
            removed = true;
        }
    }

    // TODO: use binary search to increase performance
    function insertKey(
        Mapping storage self,
        uint256 key,
        uint256 index
    ) private {
        // there is no more elements in the array to process
        if (self.keys.length == index) {
            self.indexOf[key] = self.keys.length;
            self.keys.push(key);
            return;
        }

        if (self.keys[index] < key) {
            insertKey(self, key, index + 1);
        } else {
            shiftKeysRight(self, index);
            self.keys[index] = key;
            self.indexOf[key] = index;
        }
    }

    function removeKey(Mapping storage self, uint256 key) private {
        uint256 index = self.indexOf[key];

        // TODO
    }

    function shiftKeysRight(Mapping storage self, uint256 startingIndex)
        private
    {
        uint256 index = self.keys.length - 1;

        self.keys.push(self.keys[index]); // copy last element to new cell
        self.indexOf[self.keys[index]] = index + 1;

        while (index > startingIndex) {
            self.keys[index] = self.keys[index - 1];
            self.indexOf[self.keys[index]] = index;
            index -= 1;
        }
    }

    function shiftKeysLeft(Mapping storage self, uint256 endingIndex) private {
        uint256 index = self.keys.length - 1;

        // TODO

        // while (index > endingIndex) {
        //     self.keys[index] = self.keys[index - 1];
        // }
    }
}
