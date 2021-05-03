pragma solidity >=0.8.0;

import "truffle/Assert.sol";
// import "./utils/AssertOrderType.sol";
// import "truffle/DeployedAddresses.sol";
import "../contracts/libraries/OrderSet.sol";
import "../contracts/libraries/IterableUintToOrderSetMapping.sol";

contract TestIterableUintToOrderSetMapping {
    using OrderLib for Order;
    using OrderSetLib for OrderSet;
    using IterableUintToOrderSetMapping for IterableUintToOrderSetMapping.Mapping;

    bytes32 constant orderId1 = keccak256("orderId1");
    bytes32 constant orderId3 = keccak256("orderId3");
    bytes32 constant orderId2 = keccak256("orderId2");

    uint256 constant price1 = 1001;
    uint256 constant price2 = 1002;
    uint256 constant price3 = 1003;

    uint256 constant qty1 = 1;
    address constant bidder1 = address(uint160(uint256(keccak256("bidder1"))));
    OrderType constant orderType1 = OrderType.Sell;

    uint256 constant qty2 = 2;
    address constant bidder2 = address(uint160(uint256(keccak256("bidder2"))));
    OrderType constant orderType2 = OrderType.Buy;

    IterableUintToOrderSetMapping.Mapping descendingMapping;
    IterableUintToOrderSetMapping.Mapping ascendingMapping;

    constructor() {
        descendingMapping.comparator = _greater;
        ascendingMapping.comparator = _less;
    }

    function beforeEach() external {
        _clearMapping(descendingMapping);
        _clearMapping(ascendingMapping);
    }

    function testInitialMappingIsEmpty() external {
        Assert.isTrue(descendingMapping.empty(), "Descending mapping is not empty");
        Assert.isTrue(ascendingMapping.empty(), "Ascending mapping is not empty");
    }

    function testMappingWithElementsIsNotEmpty() external {
        Order memory order; order.id = orderId1; order.price = price1;

        descendingMapping.insert(order); ascendingMapping.insert(order);

        Assert.isFalse(descendingMapping.empty(), "Descending mapping with elements should not be empty");
        Assert.isFalse(ascendingMapping.empty(), "Ascending mapping with elements should not be empty");
    }

    function testMember() external {
        Order memory order; order.id = orderId1; order.price = price1;

        descendingMapping.insert(order); ascendingMapping.insert(order);

        Assert.isTrue(descendingMapping.member(order.price), "Price for added order is not a `member` of the descending mapping");
        Assert.isTrue(ascendingMapping.member(order.price), "Price for added order is not a `member` of the ascending mapping");

        Assert.isFalse(descendingMapping.member(price2), "Price for which no order has been added is a `member` of the descending mapping");
        Assert.isFalse(ascendingMapping.member(price2), "Price for which no order has been added is a `member` of the ascending mapping");
    }

    function testInsertedOrdersWithDifferentPricesIncreaseSize() external {
        Order memory order1; order1.id = orderId1; order1.price = price1;
        descendingMapping.insert(order1); ascendingMapping.insert(order1);
        Assert.equal(descendingMapping.size(), 1, "One element has been inserted in the descending mapping");
        Assert.equal(ascendingMapping.size(), 1, "One element has been inserted in the ascending mapping");

        Order memory order2; order2.id = orderId2; order2.price = price2;
        descendingMapping.insert(order2); ascendingMapping.insert(order2);
        Assert.equal(descendingMapping.size(), 2, "Two elements have been inserted in the descending mapping");
        Assert.equal(ascendingMapping.size(), 2, "Two elements have been inserted in the ascending mapping");

        Order memory order3; order3.id = orderId3; order3.price = price3;
        descendingMapping.insert(order3); ascendingMapping.insert(order3);
        Assert.equal(descendingMapping.size(), 3, "Three elements have been inserted in the descending mapping");
        Assert.equal(ascendingMapping.size(), 3, "Three elements have been inserted in the ascending mapping");
    }

    function testInsertedOrderWithSamePriceDoesNotIncreaseSize() external {
        Order memory order1; order1.id = orderId1; order1.price = price1;
        descendingMapping.insert(order1); ascendingMapping.insert(order1);

        Order memory order2; order2.id = orderId2; order2.price = price1;
        descendingMapping.insert(order2); ascendingMapping.insert(order2);
        
        Assert.equal(descendingMapping.size(), 1, "Descending mapping should not change the size");
        Assert.equal(ascendingMapping.size(), 1, "Ascending mapping should not change the size");
    }

    function testInsertExistingOrderIdAndPriceUpdatesOrder() external {
        Order memory order = Order(orderId1, price1, qty1, bidder1, orderType1);
        ascendingMapping.insert(order);
        descendingMapping.insert(order);

        Order memory updatedOrder = Order(order.id, order.price, qty2, bidder2, orderType2);
        ascendingMapping.insert(updatedOrder);
        descendingMapping.insert(updatedOrder);
        
        Order memory getDescendingOrder = descendingMapping.get(order.price).get(order.id);
        Assert.equal(getDescendingOrder.id, updatedOrder.id, 
            "Got descending order id does not correspond to updated order id");
        Assert.equal(getDescendingOrder.price, updatedOrder.price, 
            "Got descending order price does not correspond to updated order price");
        Assert.equal(getDescendingOrder.qty, updatedOrder.qty, 
            "Got descending order qty does not correspond to updated order qty");
        Assert.equal(getDescendingOrder.bidder, updatedOrder.bidder, 
            "Got descending order bidder does not correspond to updated order bidder");
        // AssertOrderType.equal(getDescendingOrder.orderType, updatedOrder.orderType, 
        //     "Got descending order orderType does not correspond to updated order orderType");

        Order memory getAscendingOrder = ascendingMapping.get(order.price).get(order.id);
        Assert.equal(getAscendingOrder.id, updatedOrder.id, 
            "Got ascending order id does not correspond to updated order id");
        Assert.equal(getAscendingOrder.price, updatedOrder.price, 
            "Got ascending order price does not correspond to updated order price");
        Assert.equal(getAscendingOrder.qty, updatedOrder.qty, 
            "Got ascending order qty does not correspond to updated order qty");
        Assert.equal(getAscendingOrder.bidder, updatedOrder.bidder, 
            "Got ascending order bidder does not correspond to updated order bidder");
        // AssertOrderType.equal(getAscendingOrder.orderType, updatedOrder.orderType, 
        //     "Got ascending order orderType does not correspond to updated order orderType");
    }

    function testGetSortedKeys() external {
        Order memory order1; order1.id = orderId1; order1.price = price1;
        Order memory order2; order2.id = orderId2; order2.price = price2;
        Order memory order3; order3.id = orderId3; order3.price = price3;

        ascendingMapping.insert(order3); ascendingMapping.insert(order1); ascendingMapping.insert(order2);
        descendingMapping.insert(order3); descendingMapping.insert(order1); descendingMapping.insert(order2);

        uint256[] memory descendingPrices = descendingMapping.getSortedKeys();
        Assert.isTrue(_isInDescendingOrder(descendingPrices), "Sorted keys for descending mapping returned not in descending order");

        uint256[] memory ascendingPrices = ascendingMapping.getSortedKeys();
        Assert.isTrue(_isInAscendingOrder(ascendingPrices), "Sorted keys for ascending mapping returned not in ascending order");
    }

    // function testGetInsertedElements() external {
    //     Order memory order; order.id = orderId1; orderSet.insert(order);

    //     Order memory getOrder = orderSet.get(order.id);

    //     Assert.equal(getOrder.id, order.id, "Got order id does not correspond to order id");
    //     Assert.equal(getOrder.price, order.price, "Got order price does not correspond to order price");
    //     Assert.equal(getOrder.qty, order.qty, "Got order qty does not correspond to order qty");
    //     Assert.equal(getOrder.bidder, order.bidder, "Got order bidder does not correspond to order bidder");
    //     AssertOrderType.equal(getOrder.orderType, order.orderType, "Got order orderType does not correspond to order orderType");
    // }

    function testRemoveAllOrdersWithPriceDecreasesSize() external {
        Order memory order1; order1.id = orderId1; order1.price = price1;
        Order memory order2; order2.id = orderId2; order2.price = price1;
        Order memory order3; order3.id = orderId3; order3.price = price3;

        ascendingMapping.insert(order1); ascendingMapping.insert(order2); ascendingMapping.insert(order3); 

        ascendingMapping.remove(order1.price, order1.id);
        ascendingMapping.remove(order2.price, order2.id);
        Assert.equal(ascendingMapping.size(), 1, "First price should be removed from ascending mapping");

        ascendingMapping.remove(order3.price, order3.id);
        Assert.equal(ascendingMapping.size(), 0, "Second price should be removed from ascending mapping");


        descendingMapping.insert(order1); descendingMapping.insert(order2); descendingMapping.insert(order3); 

        descendingMapping.remove(order1.price, order1.id);
        descendingMapping.remove(order2.price, order2.id);
        Assert.equal(descendingMapping.size(), 1, "First price should be removed from descending mapping");

        descendingMapping.remove(order3.price, order3.id);
        Assert.equal(descendingMapping.size(), 0, "Second price should be removed from descending mapping");
    }

    function testRemoveAllOrdersWithPriceKeepsPricecOrdered() external {
        // Order memory order1; order1.id = orderId1; order1.price = price1;
        // Order memory order2; order2.id = orderId2; order2.price = price1;
        // Order memory order3; order3.id = orderId3; order3.price = price3;

        // ascendingMapping.insert(order1); ascendingMapping.insert(order2); ascendingMapping.insert(order3); 

        // ascendingMapping.remove(order1.price, order1.id);
        // ascendingMapping.remove(order2.price, order2.id);
        // Assert.equal(ascendingMapping.size(), 1, "First price should be removed from ascending mapping");

        // ascendingMapping.remove(order3.price, order3.id);
        // Assert.equal(ascendingMapping.size(), 0, "Second price should be removed from ascending mapping");


        // descendingMapping.insert(order1); descendingMapping.insert(order2); descendingMapping.insert(order3); 

        // descendingMapping.remove(order1.price, order1.id);
        // descendingMapping.remove(order2.price, order2.id);
        // Assert.equal(descendingMapping.size(), 1, "First price should be removed from descending mapping");

        // descendingMapping.remove(order3.price, order3.id);
        // Assert.equal(descendingMapping.size(), 0, "Second price should be removed from descending mapping");
    }

    function _clearMapping(IterableUintToOrderSetMapping.Mapping storage map) internal {
        while (map.keys.length > 0) {
            uint256 key = map.keys[map.keys.length - 1];

            delete map.indexOf[key];
            map.values[key].clear();
            map.keys.pop();
        }
    }

    function _less(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function _greater(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }

    function _isInDescendingOrder(uint256[] memory array) internal pure returns (bool) {
        if (array.length < 2) return true;

        for(uint256 i = 0; i < array.length - 1; i++) {
            if (array[i] < array[i+1]) return false;
        }

        return true;
    }

    function _isInAscendingOrder(uint256[] memory array) internal pure returns (bool) {
        if (array.length < 2) return true;

        for(uint256 i = 0; i < array.length - 1; i++) {
            if (array[i] > array[i+1]) return false;
        }

        return true;
    }
}
