pragma solidity >=0.8.0;

import "truffle/Assert.sol";
import "../contracts/libraries/Bytes32Set.sol";

contract TestBytes32Set {
    using Bytes32SetLib for Bytes32Set;

    bytes32 constant elem1 = keccak256("elem1");
    bytes32 constant elem2 = keccak256("elem2");
    bytes32 constant elem3 = keccak256("elem3");

    Bytes32Set set;

    function beforeEach() external {
        // Have been done manually to ensure that invalid clear will not affect tests.
        // Maybe it is better to use `clear`?
        delete set.indexOf[elem1];
        delete set.indexOf[elem2];
        delete set.indexOf[elem3];

        while (set.items.length > 0) {
            set.items.pop();
        }
    }

    function testInitialSetIsEmpty() external {
        Assert.isTrue(set.empty(), "Initially set should be empty");
    }

    function testSetWithElementsIsNotEmpty() external {
        set.insert(elem1);

        Assert.isFalse(set.empty(), "Set with elements should not be empty");
    }

    function testMember() external {
        set.insert(elem1);

        Assert.isTrue(set.member(elem1), "Element in a set should be a `member` of the set");
        Assert.isFalse(set.member(elem2), "Element not in a set should not be a `member` of the set");
    }

    function testInsertedElementsIncreaseSize() external {
        set.insert(elem1);
        Assert.equal(set.size(), 1, "One element has been inserted in the set");

        set.insert(elem2);
        Assert.equal(set.size(), 2, "Two elements have been inserted in the set");

        set.insert(elem3);
        Assert.equal(set.size(), 3, "Three elements have been inserted in the set");
    }

    function testToStorageArray() external {
        set.insert(elem1); set.insert(elem2); set.insert(elem3);

        bytes32[] storage array = set.toStorageArray();

        Assert.equal(array.length, 3, "Invalid number of elements returned in the array");
        Assert.isTrue(_inArray(array, elem1), "First order is not in the array");
        Assert.isTrue(_inArray(array, elem2), "Second order is not in the array");
        Assert.isTrue(_inArray(array, elem3), "Third order is not in the array");
    }

    function testClearMakesSetEmpty() external {
        set.insert(elem1); set.insert(elem2); set.insert(elem3);

        set.clear();
        Assert.isTrue(set.empty(), "Cleared set should be empty");
    }

    function testRemoveExistentElementDecreasesSize() external {
        set.insert(elem1); set.insert(elem2); set.insert(elem3);

        set.remove(elem1);
        Assert.equal(set.size(), 2, "First element was removed");
        set.remove(elem2);
        Assert.equal(set.size(), 1, "Second element was removed");
        set.remove(elem3);
        Assert.equal(set.size(), 0, "Third element was removed");
    }

    function testRemoveNonExistentElementDoesNotChangeSize() external {
        set.insert(elem1); set.insert(elem2);

        set.remove(elem3);
        Assert.equal(set.size(), 2, "Removing non-existent element should not change the size");

        set.remove(elem2); set.remove(elem2);
        Assert.equal(set.size(), 1, "Removing element twice should change the size only once");
    }

    function testRemovedElementIsNotMember() external {
        set.insert(elem1);

        set.remove(elem1);
        Assert.isFalse(set.member(elem1), "Removed element should not be a member");
    }

    /******************************** internal ********************************/

    function _inArray(bytes32[] memory array, bytes32 elem)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == elem) {
                return true;
            }
        }
        return false;
    }
}
