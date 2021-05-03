pragma solidity >=0.8.0;

import "truffle/Assert.sol";
import "../contracts/libraries/IterableSortedUintToBytes32SetMapping.sol";
import "../contracts/libraries/Comparators.sol";

contract TestIterableSortedUintToBytes32SetMapping {
    using Bytes32SetLib for Bytes32Set;
    using IterableSortedUintToBytes32SetMapping for IterableSortedUintToBytes32SetMapping.Mapping;

    uint256 constant key1 = 1;
    uint256 constant key2 = 2;
    uint256 constant key3 = 3;

    bytes32 constant elem1 = keccak256("elem1");
    bytes32 constant elem2 = keccak256("elem2");
    bytes32 constant elem3 = keccak256("elem3");
    bytes32 constant elem4 = keccak256("elem4");

    IterableSortedUintToBytes32SetMapping.Mapping ascendingMapping;
    IterableSortedUintToBytes32SetMapping.Mapping descendingMapping;

    constructor() {
        descendingMapping.comparator = Comparators.greater;
        ascendingMapping.comparator = Comparators.less;
    }

    function beforeEach() external {
        _clearMapping(descendingMapping);
        _clearMapping(ascendingMapping);
    }

    function testInitialAscendingMappingIsEmpty() external {
        _testInitialMappingIsEmpty(ascendingMapping);
    }

    function testInitialDescendingMappingIsEmpty() external {
        _testInitialMappingIsEmpty(descendingMapping);
    }

    function testAscendingMappingWithAddedKeyIsNotEmpty() external {
        _testMappingWithAddedKeyIsNotEmpty(ascendingMapping);
    }

    function testDescendingMappingWithAddedKeyIsNotEmpty() external {
        _testMappingWithAddedKeyIsNotEmpty(descendingMapping);
    }

    function testAscendingMappingMember() external {
        _testMember(ascendingMapping);
    }

    function testDescendingMappingMember() external {
        _testMember(descendingMapping);
    }

    function testAscendingMappingAddedKeysIncreaseSize() external {
        _testAddedKeysIncreaseSize(ascendingMapping);
    }

    function testDescendingMappingAddedKeysIncreaseSize() external {
        _testAddedKeysIncreaseSize(descendingMapping);
    }

    function testAscendingMappingAddingExistingKeyDoesNotIncreaseSize() external {
        _testAddingExistingKeyDoesNotIncreaseSize(ascendingMapping);
    }

    function testDescendingMappingAddingExistingKeyDoesNotIncreaseSize() external {
        _testAddingExistingKeyDoesNotIncreaseSize(descendingMapping);
    }

    function testAscendingMappingGetSortedKeys() external {
        _testGetSortedKeys(ascendingMapping, false);
    }

    function testDescendingMappingGetSortedKeys() external {
        _testGetSortedKeys(descendingMapping, true);
    }

    function testAscendingMappingGetAddedKeyReturnsEmptyValue() external {
        _testGetAddedKeyReturnsEmptyValue(ascendingMapping);
    }

    function testDescendingMappingGetAddedKeyReturnsEmptyValue() external {
        _testGetAddedKeyReturnsEmptyValue(descendingMapping);
    }

    function testAscendingMappingGetValuesOfAddedKey() external {
        _testGetValuesOfAddedKey(ascendingMapping);
    }

    function testDescendingMappingGetValuesOfAddedKey() external {
        _testGetValuesOfAddedKey(descendingMapping);
    }

    function testAscendingMappingRemovingKeyDecreasesSize() external {
        _testRemovingKeyDecreasesSize(ascendingMapping);
    }

    function testDescendingMappingRemovingKeyDecreasesSize() external {
        _testRemovingKeyDecreasesSize(descendingMapping);
    }

    function testAscendingMappingRemovingNonExistingKeyDoesNotChangeSize() external {
        _testRemovingNonExistingKeyDoesNotChangeSize(ascendingMapping);
    }

    function testDescendingMappingRemovingNonExistingKeyDoesNotChangeSize() external {
        _testRemovingNonExistingKeyDoesNotChangeSize(descendingMapping);
    }

    function testAscendingMappingRemovedKeyIsNotMember() external {
        _testRemovedKeyIsNotMember(ascendingMapping);
    }

    function testDescendingMappingRemovedKeyIsNotMember() external {
        _testRemovedKeyIsNotMember(descendingMapping);
    }

    function testAscendingMappingRemovingKeyClearsValue() external {
        _testRemovingKeyClearsValue(ascendingMapping);
    }

    function testDescendingMappingRemovingKeyClearsValue() external {
        _testRemovingKeyClearsValue(descendingMapping);
    }

    /******************************** implementation ********************************/

    function _testInitialMappingIsEmpty(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        Assert.isTrue(map.empty(), "Mapping is not empty");
    }

    function _testMappingWithAddedKeyIsNotEmpty(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);

        Assert.isFalse(map.empty(), "Mapping with added key should not be empty");
    }

    function _testMember(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);

        Assert.isTrue(map.member(key1), "Added key is not a `member` of the mapping");
        Assert.isFalse(map.member(key2), "Non-added key is a `member` of the mapping");
    }

    function _testAddedKeysIncreaseSize(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);
        Assert.equal(map.size(), 1, "One element has been inserted in the mapping");

        map.addKey(key2);
        Assert.equal(map.size(), 2, "Two elements have been inserted in the mapping");

        map.addKey(key3);
        Assert.equal(map.size(), 3, "Three elements have been inserted in the mapping");
    }

    function _testAddingExistingKeyDoesNotIncreaseSize(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);
        map.addKey(key1);

        Assert.equal(map.size(), 1, "Element added twice should not modify size of the mapping");
    }

    function _testGetSortedKeys(IterableSortedUintToBytes32SetMapping.Mapping storage map, bool isDesc) internal {
        map.addKey(key3); map.addKey(key1); map.addKey(key2);

        uint256[] memory keys = map.getSortedKeys();

        bool result;
        if (isDesc) {
            result = _isInDescendingOrder(keys);
        } else {
            result = _isInAscendingOrder(keys);
        }
        Assert.isTrue(result, "Mapping's sorted keys returned not in right order");
    }

    function _testGetAddedKeyReturnsEmptyValue(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);

        Assert.isTrue(map.get(key1).empty(), "'get' added key returns non-empty value");
    }

    function _testGetValuesOfAddedKey(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);
        
        Bytes32Set storage getValue = map.get(key1);
        getValue.insert(elem1); getValue.insert(elem2);

        Bytes32Set storage newGetValue = map.get(key1);
        Assert.equal(newGetValue.size(), 2, "Invalid number of items inserted in the corresponding value");
        Assert.isTrue(newGetValue.member(elem1), "First element is not a 'member' of the corresponding value");
        Assert.isTrue(newGetValue.member(elem2), "Second element is not a 'member' of the corresponding value");
    }

    function _testRemovedKeyIsNotMember(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);
        map.removeKey(key1);

        Assert.isFalse(map.member(key1), "Removed key is a member of the mapping");
    }

    function _testRemovingKeyDecreasesSize(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1); map.addKey(key2);
        
        map.removeKey(key1);
        Assert.equal(map.size(), 1, "First price should be removed from the mapping");

        map.removeKey(key2);
        Assert.equal(map.size(), 0, "Second price should be removed from the mapping");
    }

    function _testRemovingNonExistingKeyDoesNotChangeSize(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1); map.addKey(key2);

        map.removeKey(key3);
        Assert.equal(map.size(), 2, "Removing non-existing key should not change the size");

        map.removeKey(key1); map.removeKey(key1);
        Assert.equal(map.size(), 1, "Removing key twice should change the size only once");
    }

    function _testRemovingKeyClearsValue(IterableSortedUintToBytes32SetMapping.Mapping storage map) internal {
        map.addKey(key1);

        Bytes32Set storage value = map.get(key1);
        value.insert(elem1); value.insert(elem2);

        map.removeKey(key1);

        Assert.isTrue(value.empty(), "Value corresponding to removed key has not been cleared");
    }

    /******************************** internal ********************************/

    function _clearMapping(
        IterableSortedUintToBytes32SetMapping.Mapping storage map
    ) internal {
        while (map.keys.length > 0) {
            map.keys.pop();
        }

        delete map.indexOf[key1];
        delete map.indexOf[key2];
        delete map.indexOf[key3];

        map.values[key1].clear();
        map.values[key2].clear();
        map.values[key3].clear();
    }

    function _isInDescendingOrder(uint256[] memory array) private pure returns (bool) {
        if (array.length < 2) return true;

        for(uint256 i = 0; i < array.length - 1; i++) {
            if (array[i] < array[i+1]) return false;
        }

        return true;
    }

    function _isInAscendingOrder(uint256[] memory array) private pure returns (bool) {
        if (array.length < 2) return true;

        for(uint256 i = 0; i < array.length - 1; i++) {
            if (array[i] > array[i+1]) return false;
        }

        return true;
    }
}
