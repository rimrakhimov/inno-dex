// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../libraries/Bytes32Set.sol";

abstract contract InstrumentStorage {
    struct InstrumentStorageStruct {
        address asset1;
        address asset2;
        uint256 priceStep;
        address bidsOrderBook;
        address asksOrderBook;
        mapping(address => Bytes32Set) addressToOrderIds;
        mapping(address => uint256) addressToNonce;
    }

    InstrumentStorageStruct private _instrumentStorage;

    function getInstrumentStorage()
        internal
        view
        returns (InstrumentStorageStruct storage)
    {
        return _instrumentStorage;
    }

    function getAsset1() internal view returns (address) {
        return _instrumentStorage.asset1;
    }

    function setAsset1(address asset1_) internal {
        _instrumentStorage.asset1 = asset1_;
    }

    function getAsset2() internal view returns (address) {
        return _instrumentStorage.asset2;
    }

    function setAsset2(address asset2_) internal {
        _instrumentStorage.asset2 = asset2_;
    }

    function getPriceStep() internal view returns (uint256) {
        return _instrumentStorage.priceStep;
    }

    function setPriceStep(uint256 priceStep_) internal {
        _instrumentStorage.priceStep = priceStep_;
    }

    function getBidsOrderBook() internal view returns (address) {
        return _instrumentStorage.bidsOrderBook;
    }

    function setBidsOrderBook(address bidsOrderBook_) internal {
        _instrumentStorage.bidsOrderBook = bidsOrderBook_;
    }

    function getAsksOrderBook() internal view returns (address) {
        return _instrumentStorage.asksOrderBook;
    }

    function setAsksOrderBook(address asksOrderBook_) internal {
        _instrumentStorage.asksOrderBook = asksOrderBook_;
    }

    function getAddressToOrderIdsMapping()
        internal
        view
        returns (mapping(address => Bytes32Set) storage)
    {
        return _instrumentStorage.addressToOrderIds;
    }

    function getAddressToNonceMapping()
        internal
        view
        returns (mapping(address => uint256) storage)
    {
        return _instrumentStorage.addressToNonce;
    }
}
