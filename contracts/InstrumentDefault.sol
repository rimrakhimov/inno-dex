// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IInstrument.sol";
import "./OrderBook.sol";
import "./ERC20/extensions/IERC20Metadata.sol";
import "./utils/Context.sol";
import "./libraries/SharedOrderStructs.sol";

contract Instrument is IInstrument, Context {
    address _asset1;
    address _asset2;
    uint256 _priceStep;

    address _bidsOrderBook;
    address _asksOrderBook;

    mapping(address => uint256) addressToNonce;

    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) {
        _asset1 = asset1Address;
        _asset2 = asset2Address;
        _priceStep = priceStep;

        _bidsOrderBook = address(new OrderBook(OrderType.Sell));
        _asksOrderBook = address(new OrderBook(OrderType.Buy));
    }

    function getName()
        public
        view
        override(IInstrument)
        returns (string memory)
    {
        require(false, "getName");
        string memory assetSym1 = IERC20Metadata(_asset1).symbol();
        string memory assetSym2 = IERC20Metadata(_asset2).symbol();
        return string(abi.encodePacked(assetSym1, "/", assetSym2));
    }

    function getStep() external view override(IInstrument) returns (uint256) {
        return _priceStep;
    }

    function getFirstAssetAddress()
        external
        view
        override(IInstrument)
        returns (address)
    {
        return _asset1;
    }

    function getSecondAssetAddress()
        external
        view
        override(IInstrument)
        returns (address)
    {
        return _asset2;
    }

    function getMetadata()
        external
        view
        override(IInstrument)
        returns (Metadata memory)
    {
        return Metadata(_asset1, _asset2, _priceStep, getName());
    }

    function getOrderBooks() view external returns (OrderBookQty[] memory) {
        // TODO
    }

    function getOrderIds(address bidder) view external returns (bytes32[] memory) {
        // TODO
    }

    function limitOrder(
        bool toBuy,
        uint256 price,
        uint256 qty,
        uint256 flags
    ) external override(IInstrument) returns (bytes32) {
        OrderType orderType;
        if (toBuy) {
            orderType = OrderType.Buy;
        } else {
            orderType = OrderType.Sell;
        }

        bytes32 orderId =
            keccak256(
                abi.encodePacked(address(this), addressToNonce[_msgSender()]++)
            );
        Order memory order =
            Order(orderId, price, qty, _msgSender(), orderType);

        emit OrderPlaced(
            order.bidder,
            order.id,
            order.orderType,
            order.price,
            order.qty
        );

        OrderBook asksOrderBook = OrderBook(_asksOrderBook);
        OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);

        if (orderType == OrderType.Buy) {
            uint256 initialSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();

            _executeBuyOrder(order);

            uint256 finalSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Sell, finalSpotPrice);
        } else {
            uint256 initialSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();

            _executeSellOrder(order);

            uint256 finalSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Buy, finalSpotPrice);
        }

        return order.id;
    }

    function _executeBuyOrder(Order memory order) internal {
        assert(order.orderType == OrderType.Buy);

        OrderBook asksOrderBook = OrderBook(_asksOrderBook);
        OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);

        IERC20 buyAsset = IERC20(_asset1);
        IERC20 sellAsset = IERC20(_asset2);

        if (
            bidsOrderBook.empty() || bidsOrderBook.getSpotPrice() > order.price
        ) {
            asksOrderBook.add(order);
            sellAsset.transferFrom(
                _msgSender(),
                address(this),
                order.qty * order.price
            );
        } else {
            Order memory nextOrder = bidsOrderBook.getNextOrder();
            if (nextOrder.qty > order.qty) {
                uint256 qty = order.qty;
                uint256 price = nextOrder.price;

                nextOrder.qty -= qty;
                bidsOrderBook.add(nextOrder);

                sellAsset.transferFrom(
                    order.bidder,
                    nextOrder.bidder,
                    qty * price
                );
                buyAsset.transferFrom(address(this), order.bidder, qty);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(order.id);
            } else if (nextOrder.qty == order.qty) {
                uint256 qty = order.qty;
                uint256 price = nextOrder.price;

                bidsOrderBook.remove(nextOrder.id);

                sellAsset.transferFrom(
                    order.bidder,
                    nextOrder.bidder,
                    qty * price
                );
                buyAsset.transferFrom(address(this), order.bidder, qty);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(nextOrder.id);
                emit OrderExecuted(order.id);
            } else {
                uint256 qty = nextOrder.qty;
                uint256 price = nextOrder.price;

                bidsOrderBook.remove(nextOrder.id);
                sellAsset.transferFrom(
                    order.bidder,
                    nextOrder.bidder,
                    qty * price
                );
                buyAsset.transferFrom(address(this), order.bidder, qty);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(nextOrder.id);

                order.qty -= qty;
                _executeBuyOrder(order);
            }
        }
    }

    function _executeSellOrder(Order memory order) internal {
        assert(order.orderType == OrderType.Sell);

        OrderBook asksOrderBook = OrderBook(_asksOrderBook);
        OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);

        IERC20 sellAsset = IERC20(_asset1);
        IERC20 buyAsset = IERC20(_asset2);

        if (
            asksOrderBook.empty() || asksOrderBook.getSpotPrice() < order.price
        ) {
            bidsOrderBook.add(order);
            sellAsset.transferFrom(_msgSender(), address(this), order.qty);
        } else {
            Order memory nextOrder = asksOrderBook.getNextOrder();
            if (nextOrder.qty > order.qty) {
                uint256 qty = order.qty;
                uint256 price = nextOrder.price;

                nextOrder.qty -= qty;
                asksOrderBook.add(nextOrder);

                sellAsset.transferFrom(order.bidder, nextOrder.bidder, qty);
                buyAsset.transferFrom(address(this), order.bidder, qty * price);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(order.id);
            } else if (nextOrder.qty == order.qty) {
                uint256 qty = order.qty;
                uint256 price = nextOrder.price;

                asksOrderBook.remove(nextOrder.id);

                sellAsset.transferFrom(order.bidder, nextOrder.bidder, qty);
                buyAsset.transferFrom(address(this), order.bidder, qty * price);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(nextOrder.id);
                emit OrderExecuted(order.id);
            } else {
                uint256 qty = nextOrder.qty;
                uint256 price = nextOrder.price;

                asksOrderBook.remove(nextOrder.id);
                sellAsset.transferFrom(order.bidder, nextOrder.bidder, qty);
                buyAsset.transferFrom(address(this), order.bidder, qty * price);

                emit OrderPartiallyExecuted(nextOrder.id, qty, price);
                emit OrderPartiallyExecuted(order.id, qty, price);

                emit OrderExecuted(nextOrder.id);

                order.qty -= qty;
                _executeSellOrder(order);
            }
        }
    }

    function marketOrder(bool toBuy, uint256 qty)
        external
        override(IInstrument)
    {
        return;
    }

    function cancelOrder(bytes32 id) external override(IInstrument) {
        return;
    }

    // function _getOrderBooksPair(OrderType orderType)
    //     private
    //     view
    //     returns (OrderBook askedOrderBook, OrderBook inverseOrderBook)
    // {
    //     return
    //         (orderType == OrderType.Sell)
    //             ? (OrderBook(_bidsOrderBook), OrderBook(_asksOrderBook))
    //             : (OrderBook(_bidsOrderBook), OrderBook(_asksOrderBook));
    // }

    // function _getAsset(OrderType orderType) private view returns (address) {
    //     return (orderType == OrderType.Sell) ? _asset1 : _asset2;
    // }
}
