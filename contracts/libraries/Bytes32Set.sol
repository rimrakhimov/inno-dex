// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

struct Bytes32Set {
    bytes32[] items;
    mapping(bytes32 => uint256) indexOf;
}

library Bytes32SetLib {
    function size(Bytes32Set storage self) internal view returns (uint256) {
        return self.items.length;
    }

    // Returns `true` if set does not contain any element, or `false` otherwise.
    function empty(Bytes32Set storage self) internal view returns (bool) {
        return size(self) == 0;
    }

    // Check whether an element with exists in the set.
    function member(Bytes32Set storage self, bytes32 elem)
        internal
        view
        returns (bool)
    {
        return self.indexOf[elem] > 0;
    }

    // Returns array of elements from the set.
    function toStorageArray(Bytes32Set storage self)
        internal
        view
        returns (bytes32[] storage)
    {
        return self.items;
    }

    // Adds an element to the set.
    // If an element already exists in the set, the set remains the same.
    // Otherwise, a new element is added to the set and `false` is returned.
    function insert(Bytes32Set storage self, bytes32 elem)
        internal
        returns (bool replaced)
    {
        if (!member(self, elem)) {
            self.items.push(elem);

            uint256 index = self.items.length;
            self.indexOf[elem] = index;
        } else {
            uint256 index = self.indexOf[elem];
            self.items[index - 1] = elem;

            replaced = true;
        }
    }

    // Removes element from the set, if such element exists.
    // If specified element does not exist returns `false`, otherwise returns `true`.
    // Does not preserve order of elements, as a last element takes place of the element to be removed.
    function remove(Bytes32Set storage self, bytes32 elem)
        internal
        returns (bool removed)
    {
        if (member(self, elem)) {
            uint256 index = self.indexOf[elem];
            uint256 lastIndex = self.items.length;

            bytes32 lastElem = self.items[lastIndex - 1];
            self.indexOf[lastElem] = index;
            delete self.indexOf[elem];

            self.items[index - 1] = lastElem;
            self.items.pop();

            removed = true;
        }
    }

    function clear(Bytes32Set storage self) internal {
        uint256 setSize = self.items.length;
        while (setSize > 0) {
            bytes32 elem = self.items[setSize - 1];
            delete self.indexOf[elem];
            self.items.pop();

            setSize--;
        }
    }
}