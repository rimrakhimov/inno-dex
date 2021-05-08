// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrumentOrderable.sol";
import "./libraries/InstrumentOrderableLib.sol";
import "./InstrumentMetadata.sol";
import "./InstrumentStorage.sol";
import "./OrderBook.sol";
import "../libraries/SharedOrderStructs.sol";
import "../utils/Context.sol";

abstract contract InstrumentOrderable is
    IInstrumentOrderable,
    InstrumentStorage,
    InstrumentMetadata,
    Context
{
    using Bytes32SetLib for Bytes32Set;

    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) InstrumentMetadata(asset1Address, asset2Address, priceStep) {
        setBidsOrderBook(address(new OrderBook(OrderType.Sell)));
        setAsksOrderBook(address(new OrderBook(OrderType.Buy)));
    }

    function limitOrder(
        bool toBuy,
        uint256 price,
        uint256 qty,
        uint256 flags
    ) external override(IInstrumentOrderable) returns (bytes32 orderId) {
        return
            InstrumentOrderableLib.limitOrder(
                _msgSender(),
                getInstrumentStorage(),
                toBuy,
                price,
                qty,
                flags
            );
    }

    function marketOrder(bool toBuy, uint256 qty)
        external
        override(IInstrumentOrderable)
        returns (bytes32)
    {
        return
            InstrumentOrderableLib.marketOrder(
                _msgSender(),
                getInstrumentStorage(),
                toBuy,
                qty
            );
    }

    function cancelOrder(bytes32 orderId)
        external
        override(IInstrumentOrderable)
    {
        return
            InstrumentOrderableLib.cancelOrder(
                _msgSender(),
                getInstrumentStorage(),
                orderId
            );
    }
}
