const truffleAssert = require('truffle-assertions');

const Bytes32SetLib = artifacts.require("Bytes32SetLib");
const IterableSortedUintToBytes32SetMapping = artifacts.require("IterableSortedUintToBytes32SetMapping");
const OrderBook = artifacts.require("OrderBook");

const id1 = "0xabababababababababababababababababababababababababababababababab";
const id2 = "0xbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc";
const id3 = "0xcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd";
const id4 = "0xdededededededededededededededededededededededededededededededede";

const address1 = "0x1212121212121212121212121212121212121212";

var orderBookInstance;

/**************************Buy Order Book**************************/

contract("BuyOrderBook", async accounts => {
    const orderBookType = 0; // Buy

    before(async () => {
        const bytes32SetLibInstance = await Bytes32SetLib.deployed();
        const iterableSortedUintToBytes32SetMappingInstance = await IterableSortedUintToBytes32SetMapping.deployed();

        OrderBook.link("Bytes32SetLib", bytes32SetLibInstance.address);
        OrderBook.link("IterableSortedUintToBytes32SetMapping", iterableSortedUintToBytes32SetMappingInstance.address);
    });

    beforeEach(async () => {
        orderBookInstance = await OrderBook.new(orderBookType, { from: accounts[0] });
    });

    it("should be empty as only created", async () => {
        let isEmpty = await orderBookInstance.empty.call();
        assert.isTrue(isEmpty, "Created order book should be empty");
    });

    it("should not be empty if any order is added", async () => {
        let order = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        await orderBookInstance.add(order, { from: accounts[0] });

        let isEmpty = await orderBookInstance.empty.call();
        assert.isFalse(isEmpty, "Order book with inserted order should not be empty");
    })

    it("should return whether order with specified id is a member correctly", async () => {
        let order = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        await orderBookInstance.add(order, { from: accounts[0] });

        let isMember = await orderBookInstance.member.call(order.id);
        assert.isTrue(isMember, "Order id added to the order book should be a member");

        isMember = await orderBookInstance.member.call(id2);
        assert.isFalse(isMember, "Id that does not correspond to any order in the order book should be a member");
    });

    it("should return an order added to the order book", async () => {
        let order = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        await orderBookInstance.add(order, { from: accounts[0] });

        let getOrder = await orderBookInstance.getOrder.call(order.id);
        assert.equal(getOrder.id, order.id, "Order ids are not equal");
        assert.equal(getOrder.price, order.price, "Order prices are not equal");
        assert.equal(getOrder.qty, order.qty, "Order quantities are not equal");
        assert.equal(getOrder.bidder, order.bidder, "Order bidders are not equal");
        assert.equal(getOrder.orderType, order.orderType, "Order types are not equal");
    });

    it("should revert if trying to get an order that is not in the order book", async () => {
        let order = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        await orderBookInstance.add(order, { from: accounts[0] });

        await truffleAssert.reverts(orderBookInstance.getOrder(id2), "Specified order is not located in the order book");
    });

    it("should return order book records in specified order", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };
        let order3 = { id: id3, price: 3, qty: 3, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order3, { from: accounts[0] });
        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });

        let ascendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(false);
        assert.isTrue(_isInAscendingOrder(ascendingOrderBookRecords.map(function (x) { return x[0]; })),
            "Ascending order book records are not in correct order");

        let descendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(true);
        assert.isTrue(_isInDescendingOrder(descendingOrderBookRecords.map(function (x) { return x[0]; })),
            "Descending order book records are not in correct order");
    });

    it("should return correct order book records", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };
        let order3 = { id: id3, price: 2, qty: 3, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order3, { from: accounts[0] });
        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });

        let ascendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(false);
        assert.equal(ascendingOrderBookRecords.length, 2, "Invalid number of records in ascending order book record");
        assert.equal(ascendingOrderBookRecords[0].price, 1, "Invalid price in the first ascending order book record");
        assert.equal(ascendingOrderBookRecords[0].qty, 1, "Invalid quantity in the first ascending order book record");
        assert.equal(ascendingOrderBookRecords[1].price, 2, "Invalid price in the second ascending order book record");
        assert.equal(ascendingOrderBookRecords[1].qty, 5, "Invalid quantity in the second ascending order book record");

        let descendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(true);
        assert.equal(descendingOrderBookRecords.length, 2, "Invalid number of records in descending order book record");
        assert.equal(descendingOrderBookRecords[0].price, 2, "Invalid price in the first descending order book record");
        assert.equal(descendingOrderBookRecords[0].qty, 5, "Invalid quantity in the first descending order book record");
        assert.equal(descendingOrderBookRecords[1].price, 1, "Invalid price in the second descending order book record");
        assert.equal(descendingOrderBookRecords[1].qty, 1, "Invalid quantity in the second descending order book record");
    });

    it("should return empty array of no orders are in the order book", async () => {
        let ascendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(false);
        assert.equal(ascendingOrderBookRecords.length, 0, "Empty array should be returned as ascending order book records");

        let descendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(true);
        assert.equal(descendingOrderBookRecords.length, 0, "Empty array should be returned as descending order book records");
    });

    it("should return correct spot price", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };
        let order3 = { id: id3, price: 3, qty: 3, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order2, { from: accounts[0] });
        let spotPrice = await orderBookInstance.getSpotPrice.call();
        assert.equal(spotPrice, 2, "Invalid spot price after inserting order with price 2");

        await orderBookInstance.add(order3, { from: accounts[0] });
        spotPrice = await orderBookInstance.getSpotPrice.call();
        assert.equal(spotPrice, 3, "Spot price should increase after inserting order with price 3");

        await orderBookInstance.add(order1, { from: accounts[0] });
        spotPrice = await orderBookInstance.getSpotPrice.call();
        assert.equal(spotPrice, 3, "Spot price should not change after inserting order with price 1");
    });

    it("should revert if ask for spot price when no elements are in the order book", async () => {
        await truffleAssert.reverts(orderBookInstance.getSpotPrice(), "Order book is empty");
    });

    it("should return an order with spot price", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order1, { from: accounts[0] });
        let nextOrder = await orderBookInstance.getNextOrder.call();
        assert.equal(nextOrder.id, order1.id, "Next order for the spot price 1 should be returned");

        await orderBookInstance.add(order2, { from: accounts[0] });
        nextOrder = await orderBookInstance.getNextOrder.call();
        assert.equal(nextOrder.id, order2.id, "Next order for the spot price 2 should be returned");
    });

    it("should revert if ask for the next order while the order book is empty", async () => {
        await truffleAssert.reverts(orderBookInstance.getNextOrder(), "Order book is empty");
    });

    it("should add non-existing order without modification", async () => {
        let order = { id: id1, price: 1, qty: 10, bidder: address1, orderType: orderBookType };
        let modified = await orderBookInstance.add.call(order, { from: accounts[0] });
        assert.isFalse(modified, "Order should be added but not modified");
    });

    it("should modify existing order", async () => {
        let order = { id: id1, price: 1, qty: 10, bidder: address1, orderType: orderBookType };
        let updatedOrder = { id: id1, price: 1, qty: 5, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order, { from: accounts[0] });

        let modified = await orderBookInstance.add.call(updatedOrder, { from: accounts[0] });
        assert.isTrue(modified, "Order should be modified");

        await orderBookInstance.add(updatedOrder, { from: accounts[0] });

        let getOrder = await orderBookInstance.getOrder.call(order.id);
        assert.equal(getOrder.id, updatedOrder.id, "Order ids are not equal");
        assert.equal(getOrder.price, updatedOrder.price, "Order prices are not equal");
        assert.equal(getOrder.qty, updatedOrder.qty, "Order quantities are not equal");
        assert.equal(getOrder.bidder, updatedOrder.bidder, "Order bidders are not equal");
        assert.equal(getOrder.orderType, updatedOrder.orderType, "Order types are not equal");
    });

    it("should revert when trying to modify existing order with changed price", async () => {
        let order = { id: id1, price: 1, qty: 10, bidder: address1, orderType: orderBookType };
        let updatedOrder = { id: id1, price: 2, qty: 10, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order, { from: accounts[0] });

        await truffleAssert.reverts(orderBookInstance.add(updatedOrder, { from: accounts[0] }),
            "Order price cannot be changed");
    });

    it("should revert if adding an order with invalid order type", async () => {
        let invalidOrderType = (orderBookType + 1) % 2;
        let invalidOrder = { id: id1, price: 1, qty: 10, bidder: address1, orderType: invalidOrderType };

        await truffleAssert.reverts(orderBookInstance.add(invalidOrder, { from: accounts[0] }),
            "Order type does not correspond to order book type");
    });

    it("should remove order and 'member' start returning false", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });

        await orderBookInstance.remove(order1.id, { from: accounts[0] });
        let isMember = await orderBookInstance.member.call(order1.id);
        assert.isFalse(isMember, "First order has been removed");

        await orderBookInstance.remove(order2.id, { from: accounts[0] });
        isMember = await orderBookInstance.member.call(order2.id);
        assert.isFalse(isMember, "Second order has been removed");
    });

    it("should return empty if all orders are removed", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };
        let order3 = { id: id3, price: 2, qty: 2, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });
        await orderBookInstance.add(order3, { from: accounts[0] });

        await orderBookInstance.remove(order1.id, { from: accounts[0] });
        await orderBookInstance.remove(order2.id, { from: accounts[0] });
        await orderBookInstance.remove(order3.id, { from: accounts[0] });

        let isEmpty = await orderBookInstance.empty.call();
        assert.isTrue(isEmpty, "Should be empty");
    });

    it("should return correctly whether the element to be removed existed in the order book", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 1, qty: 2, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });

        let isRemoved = await orderBookInstance.remove.call(id3);
        assert.isFalse(isRemoved, "Non existent element should return that it was not removed");

        isRemoved = await orderBookInstance.remove.call(order1.id);
        assert.isTrue(isRemoved, "Existent element should return that it was removed");

        await orderBookInstance.remove(order1.id, { from: accounts[0] });
        isRemoved = await orderBookInstance.remove.call(order1.id);
        assert.isFalse(isRemoved, "Once removed element next time should return that it was not removed");
    });

    it("should throw when trying to get removed element", async () => {
        let order = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        await orderBookInstance.add(order, { from: accounts[0] });
        await orderBookInstance.remove(order.id, { from: accounts[0] });

        await truffleAssert.reverts(orderBookInstance.getOrder(order.id),
            "Specified order is not located in the order book");
    });

    it("should correctly return order book records if some orders have been removed", async () => {
        let order1 = { id: id1, price: 1, qty: 1, bidder: address1, orderType: orderBookType };
        let order2 = { id: id2, price: 2, qty: 2, bidder: address1, orderType: orderBookType };
        let order3 = { id: id3, price: 2, qty: 5, bidder: address1, orderType: orderBookType };
        let order4 = { id: id4, price: 4, qty: 4, bidder: address1, orderType: orderBookType };

        await orderBookInstance.add(order1, { from: accounts[0] });
        await orderBookInstance.add(order2, { from: accounts[0] });
        await orderBookInstance.add(order3, { from: accounts[0] });
        await orderBookInstance.add(order4, { from: accounts[0] });

        await orderBookInstance.remove(order2.id, { from: accounts[0] });
        await orderBookInstance.remove(order4.id, { from: accounts[0] });

        let ascendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(false);
        assert.equal(ascendingOrderBookRecords.length, 2, "Invalid length of ascending records");
        assert.equal(ascendingOrderBookRecords[0].price, 1,
            "Invalid price of the first record in the list of ascending records");
        assert.equal(ascendingOrderBookRecords[0].qty, 1,
            "Invalid quantity of the first record in the list of ascending records");
        assert.equal(ascendingOrderBookRecords[1].price, 2,
            "Invalid price of the second record in the list of ascending records");
        assert.equal(ascendingOrderBookRecords[1].qty, 5,
            "Invalid quantity of the second record in the list of ascending records");

        let descendingOrderBookRecords = await orderBookInstance.getOrderBookRecords.call(true);
        assert.equal(descendingOrderBookRecords.length, 2, "Invalid length of descending records");
        assert.equal(descendingOrderBookRecords[0].price, 2,
            "Invalid price of the first record in the list of descending records");
        assert.equal(descendingOrderBookRecords[0].qty, 5,
            "Invalid quantity of the first record in the list of descending records");
        assert.equal(descendingOrderBookRecords[1].price, 1,
            "Invalid price of the second record in the list of descending records");
        assert.equal(descendingOrderBookRecords[1].qty, 1,
            "Invalid quantity of the second record in the list of descending records");
    });
});

function _isInAscendingOrder(a) {
    if (a.length < 2) return true;
    for (let i = 0; i < a.length - 1; i++) {
        if (a[i] > a[i + 1]) return false;
    }
    return true;
}

function _isInDescendingOrder(a) {
    if (a.length < 2) return true;
    for (let i = 0; i < a.length - 1; i++) {
        if (a[i] < a[i + 1]) return false;
    }
    return true;
}