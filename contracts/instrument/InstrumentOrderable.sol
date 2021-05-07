// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrumentOrderable.sol";
import "./InstrumentMetadata.sol";
import "./InstrumentOrderBook.sol";
import "../libraries/SharedOrderStructs.sol";
import "../utils/Context.sol";

abstract contract InstrumentOrderable is
    IInstrumentOrderable,
    InstrumentMetadata,
    InstrumentOrderBook,
    Context
{
    using Bytes32SetLib for Bytes32Set;

    mapping(address => uint256) _addressToNonce;

    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) InstrumentMetadata(asset1Address, asset2Address, priceStep) {}

    function limitOrder(
        bool toBuy,
        uint256 price,
        uint256 qty,
        uint256
    ) external override(IInstrumentOrderable) returns (bytes32 orderId) {
        require(price > 0 && price % getStep() == 0, "Invalid price");

        orderId = keccak256(
            abi.encodePacked(_msgSender(), _addressToNonce[_msgSender()]++)
        );
        OrderType orderType = toBuy ? OrderType.Buy : OrderType.Sell;
        Order memory order =
            Order(orderId, price, qty, _msgSender(), orderType);

        emit OrderPlaced(
            order.bidder,
            order.id,
            order.orderType,
            order.price,
            order.qty
        );

        uint256 initialAsksSpotPrice = _getSpotPrice(_asksOrderBook);
        uint256 initialBidsSpotPrice = _getSpotPrice(_bidsOrderBook);

        bool executed;
        if (toBuy) {
            executed = _executeBuyOrder(order);
        } else {
            executed = _executeSellOrder(order);
        }

        if (!executed) {
            _addressToOrderIds[_msgSender()].insert(order.id);
        }

        uint256 finalAsksSpotPrice = _getSpotPrice(_asksOrderBook);
        uint256 finalBidsSpotPrice = _getSpotPrice(_bidsOrderBook);

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

    function marketOrder(bool toBuy, uint256 qty)
        external
        override(IInstrumentOrderable)
        returns (bytes32)
    {
        bytes32 orderId =
            keccak256(
                abi.encodePacked(_msgSender(), _addressToNonce[_msgSender()]++)
            );
        OrderType orderType = toBuy ? OrderType.Buy : OrderType.Sell;
        uint256 price = toBuy ? type(uint256).max : 0;
        Order memory order =
            Order(orderId, price, qty, _msgSender(), orderType);

        emit OrderPlaced(order.bidder, order.id, order.orderType, 0, order.qty);

        bool executed;
        if (toBuy) {
            uint256 initialSpotPrice = _getSpotPrice(_bidsOrderBook);
            executed = _executeBuyOrder(order);
            uint256 finalSpotPrice = _getSpotPrice(_bidsOrderBook);
            _emitSpotPriceChanged(
                OrderType.Sell,
                initialSpotPrice,
                finalSpotPrice
            );
        } else {
            uint256 initialSpotPrice = _getSpotPrice(_asksOrderBook);
            executed = _executeSellOrder(order);
            uint256 finalSpotPrice = _getSpotPrice(_asksOrderBook);
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

    function cancelOrder(bytes32 orderId)
        external
        override(IInstrumentOrderable)
    {
        require(
            _addressToOrderIds[_msgSender()].member(orderId),
            "Msg sender has no specified order"
        );

        OrderBook asksOrderBook = OrderBook(_asksOrderBook);
        OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);

        if (asksOrderBook.member(orderId)) {
            _cancelOrder(asksOrderBook, orderId);
        } else {
            _cancelOrder(bidsOrderBook, orderId);
        }

        _addressToOrderIds[_msgSender()].remove(orderId);

        emit OrderCancelled(orderId);
    }

    /******************************** internal ********************************/

    function _executeBuyOrder(Order memory order)
        internal
        returns (bool executed)
    {
        assert(order.orderType == OrderType.Buy);

        OrderBook buyAssetOrderBook = OrderBook(_bidsOrderBook);
        OrderBook sellAssetOrderBook = OrderBook(_asksOrderBook);

        IERC20 buyAsset = IERC20(getFirstAssetAddress());
        IERC20 sellAsset = IERC20(getSecondAssetAddress());

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

            _updatedOrderIds(nextOrder);
            _updateOrderBook(buyAssetOrderBook, nextOrder);

            _emitOrderExecuted(order);
            _emitOrderExecuted(nextOrder);

            if (order.qty > 0) {
                return _executeBuyOrder(order);
            }

            return true;
        }
    }

    function _executeSellOrder(Order memory order)
        internal
        returns (bool executed)
    {
        assert(order.orderType == OrderType.Sell);

        OrderBook buyAssetOrderBook = OrderBook(_asksOrderBook);
        OrderBook sellAssetOrderBook = OrderBook(_bidsOrderBook);

        IERC20 sellAsset = IERC20(getFirstAssetAddress());
        IERC20 buyAsset = IERC20(getSecondAssetAddress());

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

            _updatedOrderIds(nextOrder);
            _updateOrderBook(buyAssetOrderBook, nextOrder);

            _emitOrderExecuted(order);
            _emitOrderExecuted(nextOrder);

            if (order.qty > 0) {
                return _executeSellOrder(order);
            }

            return true;
        }
    }

    // function _executeOrder(OrderType orderType) internal {}

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

    function _updatedOrderIds(Order memory updatedOrder) internal {
        if (updatedOrder.qty == 0)
            _addressToOrderIds[updatedOrder.bidder].remove(updatedOrder.id);
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
