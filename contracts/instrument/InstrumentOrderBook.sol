// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OrderBook.sol";
import "../libraries/Bytes32Set.sol";

contract InstrumentOrderBook {
    address _bidsOrderBook;
    address _asksOrderBook;

    mapping(address => Bytes32Set) _addressToOrderIds;

    constructor() {
        _bidsOrderBook = address(new OrderBook(OrderType.Sell));
        _asksOrderBook = address(new OrderBook(OrderType.Buy));
    }
}
