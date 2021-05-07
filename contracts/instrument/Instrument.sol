// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrument.sol";
import "./InstrumentMetadata.sol";
import "./InstrumentOrderBook.sol";
import "./InstrumentOrderBookAskable.sol";
import "./InstrumentOrderable.sol";

contract Instrument is
    InstrumentMetadata,
    InstrumentOrderBook,
    InstrumentOrderBookAskable,
    InstrumentOrderable
{
    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) InstrumentOrderable(asset1Address, asset2Address, priceStep) {}
}
