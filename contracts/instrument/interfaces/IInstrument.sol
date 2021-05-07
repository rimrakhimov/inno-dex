// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IInstrumentMetadata.sol";
import "./IInstrumentOrderBookAskable.sol";
import "./IInstrumentOrderable.sol";

interface IInstrument is
    IInstrumentMetadata,
    IInstrumentOrderBookAskable,
    IInstrumentOrderable
{}
