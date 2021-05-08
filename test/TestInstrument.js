const truffleAssert = require('truffle-assertions');

const Bytes32SetLib = artifacts.require("Bytes32SetLib");
const IterableSortedUintToBytes32SetMapping = artifacts.require("IterableSortedUintToBytes32SetMapping");

const ERC20 = artifacts.require("ERC20Testable");
const WETH = artifacts.require("WETH");
const Instrument = artifacts.require("Instrument");

const maxUint = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1));

const priceStep = 100;

var tokenInstance;
var wethInstance;
var instrumentInstance;

contract("Instrument", async accounts => {
    const accountToDeploy = accounts[9];

    before(async () => {
        const bytes32SetLibInstance = await Bytes32SetLib.new();
        IterableSortedUintToBytes32SetMapping.link("Bytes32SetLib", bytes32SetLibInstance.address);
        Instrument.link("Bytes32SetLib", bytes32SetLibInstance.address);

        const iterableSortedUintToBytes32SetMappingInstance = await IterableSortedUintToBytes32SetMapping.new();
        Instrument.link("IterableSortedUintToBytes32SetMapping", iterableSortedUintToBytes32SetMappingInstance.address);
    });

    beforeEach(async () => {
        tokenInstance = await ERC20.new("Test", "TST", { from: accountToDeploy });
        wethInstance = await WETH.new({ from: accountToDeploy });
        instrumentInstance = await Instrument.new(
            tokenInstance.address, wethInstance.address, priceStep, { from: accountToDeploy }
        );

        await wethInstance.deposit({ from: accounts[0], value: 10 ** 6 });
        await wethInstance.deposit({ from: accounts[1], value: 10 ** 6 });

        await wethInstance.deposit({ from: accounts[0], value: 10 ** 6 });
        await wethInstance.deposit({ from: accounts[1], value: 10 ** 6 });

        await wethInstance.approve(instrumentInstance.address, maxUint, { from: accounts[0] });
        await wethInstance.approve(instrumentInstance.address, maxUint, { from: accounts[1] });

        await tokenInstance.requestTokens(10 ** 6, { from: accounts[0] });
        await tokenInstance.requestTokens(10 ** 6, { from: accounts[1] });

        await tokenInstance.approve(instrumentInstance.address, maxUint, { from: accounts[0] });
        await tokenInstance.approve(instrumentInstance.address, maxUint, { from: accounts[1] });
    });

    it("should add buying limit order with correct events", async () => {
        const flags = 0;
        const toBuy = true; const price = 1000; const qty = 10; const orderType = _getOrderType(toBuy);

        const orderId = await instrumentInstance.limitOrder.call(toBuy, price, qty, flags, { from: accounts[0] });

        let result = await instrumentInstance.limitOrder(toBuy, price, qty, flags, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderPlaced', {
            bidder: accounts[0],
            orderId: orderId,
            orderType: web3.utils.toBN(orderType),
            price: web3.utils.toBN(price),
            qty: web3.utils.toBN(qty),
        });
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType),
            newPrice: web3.utils.toBN(price),
        });
    });

    it("should add selling limit order with correct events", async () => {
        const flags = 0;
        const toBuy = false; const price = 1000; const qty = 10; const orderType = _getOrderType(toBuy);

        const orderId = await instrumentInstance.limitOrder.call(toBuy, price, qty, flags, { from: accounts[0] });

        let result = await instrumentInstance.limitOrder(toBuy, price, qty, flags, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderPlaced', {
            bidder: accounts[0],
            orderId: orderId,
            orderType: web3.utils.toBN(orderType),
            price: web3.utils.toBN(price),
            qty: web3.utils.toBN(qty),
        });
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType),
            newPrice: web3.utils.toBN(price),
        });
    });

    it("should add selling and buying limit orders and return correct descending order book records", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 1; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 2; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = false; const price3 = 1100; const qty3 = 3; const orderType3 = _getOrderType(toBuy3);
        const toBuy4 = false; const price4 = 1200; const qty4 = 4; const orderType4 = _getOrderType(toBuy4);
        const toBuy5 = false; const price5 = 1100; const qty5 = 5; const orderType5 = _getOrderType(toBuy5);

        await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy4, price4, qty4, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy5, price5, qty5, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        let orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 4, "Incorrect number of order book records");
        _assertEqualOrderBookRecord(orderBookRecords[0], price1, qty1, orderType1, "First");
        _assertEqualOrderBookRecord(orderBookRecords[1], price2, qty2, orderType2, "Second");
        _assertEqualOrderBookRecord(orderBookRecords[2], price3, qty3 + qty5, orderType3, "Third");
        _assertEqualOrderBookRecord(orderBookRecords[3], price4, qty4, orderType4, "Fourth");
    });

    it("should execute available buying orders, add remainder to selling order book, and emit correct events", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = false; const price3 = 800; const qty3 = 20; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.limitOrder.call(toBuy3, price3, qty3, flags, { from: accounts[0] });
        let result = await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });

        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId1,
            qty: web3.utils.toBN(qty1),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId2,
            qty: web3.utils.toBN(qty2),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty1),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty2),
        });

        truffleAssert.eventEmitted(result, 'OrderExecuted', { orderId: orderId1 });
        truffleAssert.eventEmitted(result, 'OrderExecuted', { orderId: orderId2 });

        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType3),
            newPrice: web3.utils.toBN(price3),
        });
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType1),
            newPrice: web3.utils.toBN(0),
        });

        let orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 1, "Incorrect number of order book records");
        _assertEqualOrderBookRecord(orderBookRecords[0], price3, qty3 - (qty2 + qty1), orderType3, "First");
    });

    it("should execute available selling orders, add remainder to buying order book, and emit correct events", async () => {
        const flags = 0;
        const toBuy1 = false; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = false; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = true; const price3 = 1200; const qty3 = 20; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.limitOrder.call(toBuy3, price3, qty3, flags, { from: accounts[0] });
        let result = await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });

        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId1,
            qty: web3.utils.toBN(qty1),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId2,
            qty: web3.utils.toBN(qty2),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty1),
        });
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty2),
        });

        truffleAssert.eventEmitted(result, 'OrderExecuted', { orderId: orderId1 });
        truffleAssert.eventEmitted(result, 'OrderExecuted', { orderId: orderId2 });

        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType3),
            newPrice: web3.utils.toBN(price3),
        });
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType1),
            newPrice: web3.utils.toBN(0),
        });

        let orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 1, "Incorrect number of order book records");
        _assertEqualOrderBookRecord(orderBookRecords[0], price3, qty3 - (qty2 + qty1), orderType3, "First");
    });

    // it("should correctly update spot price", async () => {

    // });

    it("should be able to cancel orders, return correct order book records, and emit correct events", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = true; const price3 = 900; const qty3 = 20; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.limitOrder.call(toBuy3, price3, qty3, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });

        let result = await instrumentInstance.cancelOrder(orderId1, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderCancelled', { orderId: orderId1 },
            "OrderCancelled event has not been emitted after first remove");
        truffleAssert.eventNotEmitted(result, 'SpotPriceChanged', {},
            "SpotPriceChanged event has been emitted after first remove");

        let orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 2, "Invalid length of order book records after first remove");
        _assertEqualOrderBookRecord(orderBookRecords[0], price3, qty3, orderType3, "After first remove, first")
        _assertEqualOrderBookRecord(orderBookRecords[1], price2, qty2, orderType2, "After first remove, second");

        result = await instrumentInstance.cancelOrder(orderId2, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderCancelled', { orderId: orderId2 },
            "OrderCancelled event has not been emitted after second remove");
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType2),
            newPrice: web3.utils.toBN(price3),
        },
            "Correct SpotPriceChanged event has not been emitted after second remove");

        orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 1, "Invalid length of order book records after the second remove");
        _assertEqualOrderBookRecord(orderBookRecords[0], price3, qty3, orderType3, "After second remove, first")

        result = await instrumentInstance.cancelOrder(orderId3, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderCancelled', { orderId: orderId3 },
            "OrderCancelled event has not been emitted after third remove");
        truffleAssert.eventEmitted(result, 'SpotPriceChanged', {
            orderBookType: web3.utils.toBN(orderType3),
            newPrice: web3.utils.toBN(0),
        },
            "Correct SpotPriceChanged event has not been emitted after third remove");

        orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 0, "Invalid length of order book records after the third remove");
    });

    it("should correctly return added order ids per user", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = false; const price3 = 1200; const qty3 = 20; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.limitOrder.call(toBuy3, price3, qty3, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });

        let orderIds = await instrumentInstance.getOrderIds.call(accounts[0]);
        assert.equal(orderIds.length, 3, "Incorrect number of order ids");
        assert.isTrue(orderIds.includes(orderId1), "First order id has not been returned");
        assert.isTrue(orderIds.includes(orderId2), "Second order id has not been returned");
        assert.isTrue(orderIds.includes(orderId3), "Third order id has not been returned");
    });

    it("should remove executed orders from user order ids", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = false; const price3 = 800; const qty3 = 20; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.limitOrder.call(toBuy3, price3, qty3, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy3, price3, qty3, flags, { from: accounts[0] });

        let orderIds = await instrumentInstance.getOrderIds.call(accounts[0]);
        assert.equal(orderIds.length, 1, "Incorrect number of order ids");
        assert.isTrue(orderIds.includes(orderId3), "Incorrect order id has been returned");
    });

    it("should correctly execute market order", async () => {
        const flags = 0;
        const toBuy1 = true; const price1 = 900; const qty1 = 10; const orderType1 = _getOrderType(toBuy1);
        const toBuy2 = true; const price2 = 1000; const qty2 = 5; const orderType2 = _getOrderType(toBuy2);
        const toBuy3 = false; const qty3 = 12; const orderType3 = _getOrderType(toBuy3);

        const orderId1 = await instrumentInstance.limitOrder.call(toBuy1, price1, qty1, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy1, price1, qty1, flags, { from: accounts[0] });

        const orderId2 = await instrumentInstance.limitOrder.call(toBuy2, price2, qty2, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy2, price2, qty2, flags, { from: accounts[0] });

        const orderId3 = await instrumentInstance.marketOrder.call(toBuy3, qty3, { from: accounts[0] });
        let result = await instrumentInstance.marketOrder(toBuy3, qty3, { from: accounts[0] });
        truffleAssert.eventEmitted(result, 'OrderPlaced', {
            orderId: orderId3,
            bidder: accounts[0],
            orderType: web3.utils.toBN(orderType3),
            price: web3.utils.toBN(0),
            qty: web3.utils.toBN(qty3),
        }, "OrderPlaced event has not been emitted");

        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId1,
            qty: web3.utils.toBN(qty3 - qty2),
            price: web3.utils.toBN(price1),
        }, "OrderPartiallyExecuted event has not been emitted for the first order");
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId2,
            qty: web3.utils.toBN(qty2),
            price: web3.utils.toBN(price2),
        }, "OrderPartiallyExecuted event has not been emitted for the second order");
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty2),
            price: web3.utils.toBN(price2),
        }, "OrderPartiallyExecuted event has not been emitted for the third order when second order executed");
        truffleAssert.eventEmitted(result, 'OrderPartiallyExecuted', {
            orderId: orderId3,
            qty: web3.utils.toBN(qty3 - qty2),
            price: web3.utils.toBN(price1),
        }, "OrderPartiallyExecuted event has not been emitted for the third order when first order executed");

        truffleAssert.eventEmitted(result, 'OrderExecuted', {
            orderId: orderId2,
        }, "OrderExecuted event has not been emitted for the second order");
        truffleAssert.eventEmitted(result, 'OrderExecuted', {
            orderId: orderId3,
        }, "OrderExecuted event has not been emitted for the third order");

        let orderBookRecords = await instrumentInstance.getOrderBookRecords.call();
        assert.equal(orderBookRecords.length, 1, "Incorrect number of order book records");
        _assertEqualOrderBookRecord(orderBookRecords[0], price1, qty1 - (qty3 - qty2), orderType1, "First");

        let orderIds = await instrumentInstance.getOrderIds.call(accounts[0]);
        assert.equal(orderIds.length, 1, "Incorrect number of order ids");
        assert.isTrue(orderIds.includes(orderId1), "First order is not in order ids list");
    });

    it("should return tokens back to bidder when sell order is cancelled", async () => {
        const flags = 0;
        const toBuy = false; const price = 900; const qty = 10; const orderType = _getOrderType(toBuy);

        const initialBalance = await tokenInstance.balanceOf.call(accounts[0]);

        const orderId = await instrumentInstance.limitOrder.call(toBuy, price, qty, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy, price, qty, flags, { from: accounts[0] });

        let balance = await tokenInstance.balanceOf.call(accounts[0]);
        assert.equal(balance, initialBalance - qty, "Making an order changed bidder's balance incorrectly");

        await instrumentInstance.cancelOrder(orderId, { from: accounts[0] });

        balance = await tokenInstance.balanceOf.call(accounts[0]);
        assert.equal(balance.toString(), initialBalance.toString(), "Cancelling order did not returned tokens back");
    });

    it("should return tokens back to bidder when buy order is cancelled", async () => {
        const flags = 0;
        const toBuy = true; const price = 900; const qty = 10; const orderType = _getOrderType(toBuy);

        const initialBalance = await wethInstance.balanceOf.call(accounts[0]);

        const orderId = await instrumentInstance.limitOrder.call(toBuy, price, qty, flags, { from: accounts[0] });
        await instrumentInstance.limitOrder(toBuy, price, qty, flags, { from: accounts[0] });

        let balance = await wethInstance.balanceOf.call(accounts[0]);
        assert.equal(balance, initialBalance - (qty * price), "Making an order changed bidder's balance incorrectly");

        await instrumentInstance.cancelOrder(orderId, { from: accounts[0] });

        balance = await wethInstance.balanceOf.call(accounts[0]);
        assert.equal(balance.toString(), initialBalance.toString(), "Cancelling order did not returned tokens back");
    });
});

function _getOrderType(toBuy) {
    return (toBuy ? 0 : 1);
}

function _assertEqualOrderBookRecord(record, price, qty, orderType, prefix) {
    assert.equal(record.price, price, prefix.concat(" order book record's price is incorrect"));
    assert.equal(record.qty, qty, prefix.concat(" order book record's quantity is incorrect"));
    assert.equal(record.orderType, orderType, prefix.concat(" order book record's order type is incorrect"));
}