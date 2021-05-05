// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IInstrument.sol";
import "./OrderBook.sol";
import "../ERC20/extensions/IERC20Metadata.sol";
import "../utils/Context.sol";
import "../libraries/SharedOrderStructs.sol";

abstract contract Instrument is IInstrument, Context {
    address _asset1;
    address _asset2;
    uint256 _priceStep;

    address _bidsOrderBook;
    address _asksOrderBook;

    mapping(address => uint256) _addressToNonce;

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
}
