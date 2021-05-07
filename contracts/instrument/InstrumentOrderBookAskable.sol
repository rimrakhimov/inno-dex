// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrumentOrderBookAskable.sol";
import "./InstrumentOrderBook.sol";
import "../libraries/SharedOrderStructs.sol";
import "./OrderBook.sol";

abstract contract InstrumentOrderBookAskable is
    IInstrumentOrderBookAskable,
    InstrumentOrderBook
{
    using Bytes32SetLib for Bytes32Set;

    function getOrder(bytes32 orderId)
        external
        view
        override(IInstrumentOrderBookAskable)
        returns (Order memory)
    {
        OrderBook bidsOrderBook = OrderBook(_bidsOrderBook);
        OrderBook asksOrderBook = OrderBook(_asksOrderBook);

        // If the order is not neither in bids order book nor in asks order book,
        // transaction will be reverted when trying to get the order from asks order book.
        return
            (bidsOrderBook.member(orderId))
                ? bidsOrderBook.getOrder(orderId)
                : asksOrderBook.getOrder(orderId);
    }

    function getOrderBookRecords()
        external
        view
        override(IInstrumentOrderBookAskable)
        returns (OrderBookRecord[] memory)
    {
        OrderBookRecord[] memory askRecords =
            OrderBook(_asksOrderBook).getOrderBookRecords(false);
        OrderBookRecord[] memory bidRecords =
            OrderBook(_bidsOrderBook).getOrderBookRecords(false);
        return _concatArrays(askRecords, bidRecords);
    }

    function getOrderIds(address bidder)
        external
        view
        override(IInstrumentOrderBookAskable)
        returns (bytes32[] memory)
    {
        return _addressToOrderIds[bidder].toStorageArray();
    }

    /******************************** private ********************************/

    function _concatArrays(
        OrderBookRecord[] memory a,
        OrderBookRecord[] memory b
    ) private pure returns (OrderBookRecord[] memory) {
        uint256 size1 = a.length;
        uint256 size2 = b.length;
        OrderBookRecord[] memory result = new OrderBookRecord[](size1 + size2);

        for (uint256 i = 0; i < size1; i++) {
            result[i] = a[i];
        }
        for (uint256 i = 0; i < size2; i++) {
            result[size1 + i] = b[i];
        }
        return result;
    }
}
