// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IInstrument.sol";
import "./OrderBook.sol";
import "./ERC20/extensions/IERC20Metadata.sol";
import "./utils/Context.sol";
import "./libraries/SharedOrderStructs.sol";
import "./libraries/Bytes32Set.sol";

contract Instrument is IInstrument, Context {
    using Bytes32SetLib for Bytes32Set;

    address _asset1;
    address _asset2;
    uint256 _priceStep;

    address _bidsOrderBook;
    address _asksOrderBook;

    mapping(address => uint256) addressToNonce;
    mapping(address => Bytes32Set) addressToOrderIds;
    mapping(bytes32 => OrderType) orderIdToOrderType;

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
    
    function getSpotPrice(bool asks) external view returns (uint256) {
        if (asks) {
            return OrderBook(_asksOrderBook).empty() ? 0 : OrderBook(_asksOrderBook).getSpotPrice();
        } else {
            return OrderBook(_bidsOrderBook).empty() ? 0 : OrderBook(_bidsOrderBook).getSpotPrice();
        }
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        OrderBook orderBook;
        if (orderIdToOrderType[orderId] == OrderType.Sell) {
            orderBook = OrderBook(_bidsOrderBook);
        } else {
            orderBook = OrderBook(_asksOrderBook);
        }
        return orderBook.getOrder(orderId);
    }

    function getOrderBookRecords()
        external
        view
        returns (OrderBookQty[] memory)
    {
        OrderBookQty[] memory bidRecords =
            OrderBook(_bidsOrderBook).getOrderBookQtys();
        OrderBookQty[] memory askRecords =
            OrderBook(_asksOrderBook).getOrderBookQtys();

        return _concatArrays(_reverseArray(askRecords), bidRecords);
    }

    function getOrderIds(address bidder)
        external
        view
        returns (bytes32[] memory)
    {
        return addressToOrderIds[bidder].toStorageArray();
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

        if (orderType == OrderType.Buy) {
            OrderBook asksOrderBook = OrderBook(_asksOrderBook);
            uint256 initialSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();

            asksOrderBook.add(order);

            uint256 finalSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Buy, finalSpotPrice);
        } else {
            OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);
            uint256 initialSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();

            bidsOrderBook.add(order);

            uint256 finalSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Sell, finalSpotPrice);
        }

        orderIdToOrderType[order.id] = order.orderType;
        addressToOrderIds[_msgSender()].insert(order.id);

        return order.id;
    }

    function marketOrder(bool toBuy, uint256 qty)
        external
        override(IInstrument)
    {
        return;
    }

    function cancelOrder(bytes32 orderId) external override(IInstrument) {
        if (orderIdToOrderType[orderId] == OrderType.Buy) {
            OrderBook asksOrderBook = OrderBook(_asksOrderBook);
            uint256 initialSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();


            addressToOrderIds[_msgSender()].remove(orderId);
            delete orderIdToOrderType[orderId];
            asksOrderBook.remove(orderId);
            emit OrderCancelled(orderId);

            uint256 finalSpotPrice =
                asksOrderBook.empty() ? 0 : asksOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Buy, finalSpotPrice);
        } else {
            OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);
            uint256 initialSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();

            addressToOrderIds[_msgSender()].remove(orderId);
            delete orderIdToOrderType[orderId];
            bidsOrderBook.remove(orderId);
            emit OrderCancelled(orderId);

            uint256 finalSpotPrice =
                bidsOrderBook.empty() ? 0 : bidsOrderBook.getSpotPrice();
            if (finalSpotPrice != initialSpotPrice)
                emit SpotPriceChanged(OrderType.Sell, finalSpotPrice);
        }
    }

    function _reverseArray(OrderBookQty[] memory array)
        private
        pure
        returns (OrderBookQty[] memory)
    {
        uint256 size = array.length;
        OrderBookQty[] memory result = new OrderBookQty[](size);

        for (uint256 i = 0; i < size; i++) {
            result[i] = array[size - i - 1];
        }
        return result;
    }

    function _concatArrays(OrderBookQty[] memory a, OrderBookQty[] memory b)
        private
        pure
        returns (OrderBookQty[] memory)
    {
        uint256 size1 = a.length;
        uint256 size2 = b.length;
        OrderBookQty[] memory result = new OrderBookQty[](size1 + size2);

        for (uint256 i = 0; i < size1; i++) {
            result[i] = a[size1 - i - 1];
        }
        for (uint256 i = 0; i < size2; i++) {
            result[size1 + i] = b[size2 - i - 1];
        }
        return result;
    }
}
