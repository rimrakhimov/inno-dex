// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../ERC20/IERC20.sol";
import "../interfaces/IInstrument.sol";
import "../InstrumentStorage.sol";
import "../OrderBook.sol";
import "../../libraries/SharedOrderStructs.sol";

library InstrumentOrderableLib {
    using Bytes32SetLib for Bytes32Set;

    event OrderPlaced(
        address indexed bidder,
        bytes32 orderId,
        OrderType orderType,
        uint256 price,
        uint256 qty
    );

    event SpotPriceChanged(OrderType orderBookType, uint256 newPrice);
    event OrderCancelled(bytes32 orderId);
    event OrderExecuted(bytes32 orderId);
    event OrderPartiallyExecuted(
        bytes32 indexed orderId,
        uint256 qty,
        uint256 price
    );

    function limitOrder(
        address msgSender,
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        bool toBuy,
        uint256 price,
        uint256 qty,
        uint256
    ) external returns (bytes32 orderId) {
        require(
            price > 0 && price % instrumentStorage.priceStep == 0,
            "Invalid price"
        );

        orderId = keccak256(
            abi.encodePacked(
                msgSender,
                instrumentStorage.addressToNonce[msgSender]++
            )
        );
        OrderType orderType = toBuy ? OrderType.Buy : OrderType.Sell;
        Order memory order = Order(orderId, price, qty, msgSender, orderType);

        emit OrderPlaced(
            order.bidder,
            order.id,
            order.orderType,
            order.price,
            order.qty
        );

        uint256 initialAsksSpotPrice =
            _getSpotPrice(instrumentStorage.asksOrderBook);
        uint256 initialBidsSpotPrice =
            _getSpotPrice(instrumentStorage.bidsOrderBook);

        bool executed;
        if (toBuy) {
            executed = _executeBuyOrder(instrumentStorage, order);
        } else {
            executed = _executeSellOrder(instrumentStorage, order);
        }

        if (!executed) {
            instrumentStorage.addressToOrderIds[msgSender].insert(order.id);
        }

        uint256 finalAsksSpotPrice =
            _getSpotPrice(instrumentStorage.asksOrderBook);
        uint256 finalBidsSpotPrice =
            _getSpotPrice(instrumentStorage.bidsOrderBook);

        _emitSpotPriceChanged(
            OrderType.Buy,
            initialAsksSpotPrice,
            finalAsksSpotPrice
        );
        _emitSpotPriceChanged(
            OrderType.Sell,
            initialBidsSpotPrice,
            finalBidsSpotPrice
        );
    }

    function marketOrder(
        address msgSender,
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        bool toBuy,
        uint256 qty
    ) external returns (bytes32) {
        bytes32 orderId =
            keccak256(
                abi.encodePacked(
                    msgSender,
                    instrumentStorage.addressToNonce[msgSender]++
                )
            );
        OrderType orderType = toBuy ? OrderType.Buy : OrderType.Sell;
        uint256 price = toBuy ? type(uint256).max : 0;
        Order memory order = Order(orderId, price, qty, msgSender, orderType);

        emit OrderPlaced(order.bidder, order.id, order.orderType, 0, order.qty);

        bool executed;
        if (toBuy) {
            uint256 initialSpotPrice =
                _getSpotPrice(instrumentStorage.bidsOrderBook);
            executed = _executeBuyOrder(instrumentStorage, order);
            uint256 finalSpotPrice =
                _getSpotPrice(instrumentStorage.bidsOrderBook);
            _emitSpotPriceChanged(
                OrderType.Sell,
                initialSpotPrice,
                finalSpotPrice
            );
        } else {
            uint256 initialSpotPrice =
                _getSpotPrice(instrumentStorage.asksOrderBook);
            executed = _executeSellOrder(instrumentStorage, order);
            uint256 finalSpotPrice =
                _getSpotPrice(instrumentStorage.asksOrderBook);
            _emitSpotPriceChanged(
                OrderType.Sell,
                initialSpotPrice,
                finalSpotPrice
            );
        }

        if (!executed) {
            revert("Order cannot be executed");
        }

        return order.id;
    }

    function cancelOrder(
        address msgSender,
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        bytes32 orderId
    ) external {
        require(
            instrumentStorage.addressToOrderIds[msgSender].member(orderId),
            "Msg sender has no specified order"
        );

        OrderBook asksOrderBook = OrderBook(instrumentStorage.asksOrderBook);
        OrderBook bidsOrderBook = OrderBook(instrumentStorage.bidsOrderBook);

        if (asksOrderBook.member(orderId)) {
            Order memory order = asksOrderBook.getOrder(orderId);
            _returnTokens(
                instrumentStorage.asset2,
                order.bidder,
                order.qty * order.price
            );
            _cancelOrder(asksOrderBook, orderId);
        } else {
            Order memory order = bidsOrderBook.getOrder(orderId);
            _returnTokens(instrumentStorage.asset1, order.bidder, order.qty);
            _cancelOrder(bidsOrderBook, orderId);
        }

        instrumentStorage.addressToOrderIds[msgSender].remove(orderId);

        emit OrderCancelled(orderId);
    }

    /******************************** internal ********************************/

    function _executeBuyOrder(
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        Order memory order
    ) internal returns (bool executed) {
        assert(order.orderType == OrderType.Buy);

        OrderBook buyAssetOrderBook =
            OrderBook(instrumentStorage.bidsOrderBook);
        OrderBook sellAssetOrderBook =
            OrderBook(instrumentStorage.asksOrderBook);

        IERC20 buyAsset = IERC20(instrumentStorage.asset1);
        IERC20 sellAsset = IERC20(instrumentStorage.asset2);

        if (
            buyAssetOrderBook.empty() ||
            buyAssetOrderBook.getSpotPrice() > order.price
        ) {
            sellAssetOrderBook.add(order);
            sellAsset.transferFrom(
                order.bidder,
                address(this),
                order.qty * order.price
            );
        } else {
            Order memory nextOrder = buyAssetOrderBook.getNextOrder();
            assert(nextOrder.price <= order.price);

            uint256 price = nextOrder.price;
            uint256 qty = _min(order.qty, nextOrder.qty);

            sellAsset.transferFrom(order.bidder, nextOrder.bidder, qty * price);
            buyAsset.transfer(order.bidder, qty);

            emit OrderPartiallyExecuted(order.id, qty, price);
            emit OrderPartiallyExecuted(nextOrder.id, qty, price);

            // Update orders and proceed
            order.qty -= qty;
            nextOrder.qty -= qty;

            _updatedOrderIds(instrumentStorage, nextOrder);
            _updateOrderBook(buyAssetOrderBook, nextOrder);

            _emitOrderExecuted(order);
            _emitOrderExecuted(nextOrder);

            if (order.qty > 0) {
                return _executeBuyOrder(instrumentStorage, order);
            }

            return true;
        }
    }

    function _executeSellOrder(
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        Order memory order
    ) internal returns (bool executed) {
        assert(order.orderType == OrderType.Sell);

        OrderBook buyAssetOrderBook =
            OrderBook(instrumentStorage.asksOrderBook);
        OrderBook sellAssetOrderBook =
            OrderBook(instrumentStorage.bidsOrderBook);

        IERC20 sellAsset = IERC20(instrumentStorage.asset1);
        IERC20 buyAsset = IERC20(instrumentStorage.asset2);

        if (
            buyAssetOrderBook.empty() ||
            buyAssetOrderBook.getSpotPrice() < order.price
        ) {
            sellAssetOrderBook.add(order);
            sellAsset.transferFrom(order.bidder, address(this), order.qty);
        } else {
            Order memory nextOrder = buyAssetOrderBook.getNextOrder();
            assert(nextOrder.price >= order.price);

            uint256 price = nextOrder.price;
            uint256 qty = _min(order.qty, nextOrder.qty);

            sellAsset.transferFrom(order.bidder, nextOrder.bidder, qty);
            buyAsset.transfer(order.bidder, qty * price);

            emit OrderPartiallyExecuted(order.id, qty, price);
            emit OrderPartiallyExecuted(nextOrder.id, qty, price);

            // Update orders and proceed
            order.qty -= qty;
            nextOrder.qty -= qty;

            _updatedOrderIds(instrumentStorage, nextOrder);
            _updateOrderBook(buyAssetOrderBook, nextOrder);

            _emitOrderExecuted(order);
            _emitOrderExecuted(nextOrder);

            if (order.qty > 0) {
                return _executeSellOrder(instrumentStorage, order);
            }

            return true;
        }
    }

    function _returnTokens(
        address asset,
        address receiver,
        uint256 qty
    ) internal {
        IERC20(asset).transfer(receiver, qty);
    }

    function _cancelOrder(OrderBook orderBook, bytes32 orderId) internal {
        uint256 initialSpotPrice = _getSpotPrice(address(orderBook));
        orderBook.remove(orderId);
        uint256 finalSpotPrice = _getSpotPrice(address(orderBook));
        _emitSpotPriceChanged(
            orderBook.getOrderBookType(),
            initialSpotPrice,
            finalSpotPrice
        );
    }

    function _updatedOrderIds(
        InstrumentStorage.InstrumentStorageStruct storage instrumentStorage,
        Order memory updatedOrder
    ) internal {
        if (updatedOrder.qty == 0)
            instrumentStorage.addressToOrderIds[updatedOrder.bidder].remove(
                updatedOrder.id
            );
    }

    function _updateOrderBook(OrderBook orderBook, Order memory updatedOrder)
        internal
    {
        updatedOrder.qty > 0
            ? orderBook.add(updatedOrder)
            : orderBook.remove(updatedOrder.id);
    }

    function _emitOrderExecuted(Order memory order) internal {
        if (order.qty == 0) emit OrderExecuted(order.id);
    }

    function _emitSpotPriceChanged(
        OrderType orderBookType,
        uint256 initialSpotPrice,
        uint256 newSpotPrice
    ) internal {
        if (initialSpotPrice != newSpotPrice)
            emit SpotPriceChanged(orderBookType, newSpotPrice);
    }

    function _getSpotPrice(address orderBookAddress)
        internal
        view
        returns (uint256)
    {
        OrderBook orderBook = OrderBook(orderBookAddress);
        return orderBook.empty() ? 0 : orderBook.getSpotPrice();
    }

    /******************************** private ********************************/

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
