pragma solidity >=0.8.0;

import "truffle/Assert.sol";
import "./utils/AssertOrderType.sol";
import "../contracts/libraries/OrderSet.sol";

contract TestOrderSet {
    using OrderLib for Order;
    using OrderSetLib for OrderSet;

    bytes32 constant orderId1 = keccak256("orderId1");
    bytes32 constant orderId3 = keccak256("orderId3");
    bytes32 constant orderId2 = keccak256("orderId2");

    uint256 constant price1 = 1001;
    uint256 constant qty1 = 1;
    address constant bidder1 = address(uint160(uint256(keccak256("bidder1"))));
    OrderType constant orderType1 = OrderType.Sell;

    uint256 constant price2 = 1002;
    uint256 constant qty2 = 2;
    address constant bidder2 = address(uint160(uint256(keccak256("bidder2"))));
    OrderType constant orderType2 = OrderType.Buy;

    OrderSet orderSet;

    function beforeEach() external {
        // orderSet.clear();

        // Have been done manually to ensure that invalid clear will not affect tests.
        // Maybe it is better to use `clear`?
        delete orderSet.indexOf[orderId1];
        delete orderSet.indexOf[orderId2];
        delete orderSet.indexOf[orderId3];

        while (orderSet.orders.length > 0) {
            orderSet.orders.pop();
        }
    }

    function testInitialOrderSetIsEmpty() external {
        Assert.isTrue(orderSet.empty(), "Initially order set should be empty");
    }

    function testOrderSetWithElementsIsNotEmpty() external {
        Order memory order; order.id = orderId1; orderSet.insert(order);

        Assert.isFalse(orderSet.empty(), "Order set with elements should not be empty");
    }

    function testMember() external {
        Order memory order; order.id = orderId1; orderSet.insert(order);

        Assert.isTrue(orderSet.member(order.id), "Element in a set should be a `member` of the set");
        Assert.isFalse(orderSet.member(orderId2), "Element not in a set should not be a `member` of the set");
    }

    function testInsertedElementsIncreaseSize() external {
        Order memory order1; order1.id = orderId1; orderSet.insert(order1);
        Assert.equal(orderSet.size(), 1, "One element has been inserted in the set");

        Order memory order2; order2.id = orderId2; orderSet.insert(order2);
        Assert.equal(orderSet.size(), 2, "Two elements have been inserted in the set");

        Order memory order3; order3.id = orderId3; orderSet.insert(order3);
        Assert.equal(orderSet.size(), 3, "Three elements have been inserted in the set");
    }

    function testGetInsertedElements() external {
        Order memory order; order.id = orderId1; orderSet.insert(order);

        Order memory getOrder = orderSet.get(order.id);

        Assert.equal(getOrder.id, order.id, "Got order id does not correspond to order id");
        Assert.equal(getOrder.price, order.price, "Got order price does not correspond to order price");
        Assert.equal(getOrder.qty, order.qty, "Got order qty does not correspond to order qty");
        Assert.equal(getOrder.bidder, order.bidder, "Got order bidder does not correspond to order bidder");
        AssertOrderType.equal(getOrder.orderType, order.orderType, "Got order orderType does not correspond to order orderType");
    }

    function testToStorageArray() external {
        Order memory order1; order1.id = orderId1; orderSet.insert(order1);
        Order memory order2; order2.id = orderId2; orderSet.insert(order2);
        Order memory order3; order3.id = orderId3; orderSet.insert(order3);

        Order[] storage array = orderSet.toStorageArray();

        Assert.equal(array.length, 3, "Invalid number of elements returned in the array");
        Assert.isTrue(_inArray(array, order1), "First order is not in the array");
        Assert.isTrue(_inArray(array, order2), "Second order is not in the array");
        Assert.isTrue(_inArray(array, order3), "Third order is not in the array");
    }

    function testClearMakesSetEmpty() external {
        Order memory order1; order1.id = orderId1; orderSet.insert(order1);
        Order memory order2; order2.id = orderId2; orderSet.insert(order2);
        Order memory order3; order3.id = orderId3; orderSet.insert(order3);

        orderSet.clear();
        Assert.isTrue(orderSet.empty(), "Cleared order set should be empty");
    }

    function testInsertExistingOrderIdUpdatesOrder() external {
        Order memory order = Order(orderId1, price1, qty1, bidder1, orderType1);
        orderSet.insert(order);

        Order memory updatedOrder = Order(order.id, price2, qty2, bidder2, orderType2);
        orderSet.insert(updatedOrder);
        
        Order memory getOrder = orderSet.get(order.id);
        
        Assert.equal(getOrder.id, updatedOrder.id, "Got order id does not correspond to updated order id");
        Assert.equal(getOrder.price, updatedOrder.price, "Got order price does not correspond to updated order price");
        Assert.equal(getOrder.qty, updatedOrder.qty, "Got order qty does not correspond to updated order qty");
        Assert.equal(getOrder.bidder, updatedOrder.bidder, "Got order bidder does not correspond to updated order bidder");
        AssertOrderType.equal(getOrder.orderType, updatedOrder.orderType, "Got order orderType does not correspond to updated order orderType");
    }

    function testRemoveExistentElementDecreasesSize() external {
        Order memory order1; order1.id = orderId1; orderSet.insert(order1);
        Order memory order2; order2.id = orderId2; orderSet.insert(order2);
        Order memory order3; order3.id = orderId3; orderSet.insert(order3);

        orderSet.remove(order1.id);
        Assert.equal(orderSet.size(), 2, "First element was removed");
        orderSet.remove(order2.id);
        Assert.equal(orderSet.size(), 1, "Second element was removed");
        orderSet.remove(order3.id);
        Assert.equal(orderSet.size(), 0, "Third element was removed");
    }

    function testRemoveNonExistentElementDoesNotChangeSize() external {
        Order memory order1; order1.id = orderId1; orderSet.insert(order1);
        Order memory order2; order2.id = orderId2; orderSet.insert(order2);

        orderSet.remove(orderId3);
        Assert.equal(orderSet.size(), 2, "Removing non-existent element should not change size");

        orderSet.remove(order2.id); orderSet.remove(order2.id);
        Assert.equal(orderSet.size(), 1, "Removing once removed element should change size only once");
    }

    function testRemovedElementIsNotMember() external {
        Order memory order; order.id = orderId1; orderSet.insert(order);

        orderSet.remove(order.id);
        Assert.isFalse(orderSet.member(order.id), "Removed element should not be a member");
    }

    // function testGetNonExistentElementFails() external {
        // (bool r, ) = OrderSetLib.delegatecall(abi.encodePacked(OrderSetLib.get.selector), orderSet);
    // }

    // function testGetRemovedElementFails() external {}

    function _inArray(Order[] memory array, Order memory elem)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].equal(elem)) {
                return true;
            }
        }
        return false;
    }
}
