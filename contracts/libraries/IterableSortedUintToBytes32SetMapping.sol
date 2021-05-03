// SPDX-License-Identifier: MIT

import "./Bytes32Set.sol";

pragma solidity ^0.8.3;

library IterableSortedUintToBytes32SetMapping {
    using Bytes32SetLib for Bytes32Set;

    struct Mapping {
        uint256[] keys;
        mapping(uint256 => Bytes32Set) values;
        mapping(uint256 => uint256) indexOf;
        function(uint256, uint256) internal pure returns (bool) comparator;
    }

    function member(Mapping storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.indexOf[key] > 0;
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
        returns (Bytes32Set storage)
    {
        require(member(self, key), "Key does not exist");
        return self.values[key];
    }

    function getSortedKeys(Mapping storage self)
        internal
        view
        returns (uint256[] storage)
    {
        return self.keys;
    }

    function addKey(Mapping storage self, uint256 key)
        internal
        returns (bool added)
    {
        if (!member(self, key)) {
            _insertKey(self, key, 0);
            added = true;
        }
    }

    // Removed key from the mapping. 
    // Value corresponding to the key is cleared.
    function removeKey(Mapping storage self, uint256 key)
        internal
        returns (bool removed)
    {
        if (member(self, key)) {
            self.values[key].clear(); // clear the value before removing the key
            _removeKey(self, key);
            removed = true;
        }
    }

    /******************************** internal ********************************/

    // TODO: use binary search to increase performance
    function _insertKey(
        Mapping storage self,
        uint256 key,
        uint256 index
    ) private {
        // there is no more elements in the array to process
        if (self.keys.length == index) {
            self.keys.push(key);
            self.indexOf[key] = self.keys.length;
            return;
        }

        if (self.comparator(self.keys[index], key)) {
            _insertKey(self, key, index + 1);
        } else {
            _shiftKeysRight(self, index);
            self.keys[index] = key;
            self.indexOf[key] = index + 1;
        }
    }

    function _removeKey(Mapping storage self, uint256 key) private {
        uint256 index = self.indexOf[key];
        delete self.indexOf[key];
        _shiftKeysLeft(self, index - 1);
    }

    function _shiftKeysRight(Mapping storage self, uint256 startingIndex)
        private
    {
        uint256 index = self.keys.length - 1;

        self.keys.push(self.keys[index]); // copies last element to new cell
        self.indexOf[self.keys[index]] = (index + 1) + 1;

        while (index > startingIndex) {
            self.keys[index] = self.keys[index - 1];
            self.indexOf[self.keys[index]] = index + 1;
            index -= 1;
        }
    }

    function _shiftKeysLeft(Mapping storage self, uint256 startingIndex)
        private
    {
        uint256 index = startingIndex;
        while (index < self.keys.length - 1) {
            self.keys[index] = self.keys[index + 1];
            self.indexOf[self.keys[index]] = index + 1;
            index++;
        }
        self.keys.pop();
    }
}
