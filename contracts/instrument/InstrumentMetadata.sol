// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrumentMetadata.sol";
import "../ERC20/extensions/IERC20Metadata.sol";

abstract contract InstrumentMetadata is IInstrumentMetadata {
    address private _asset1;
    address private _asset2;
    uint256 private _priceStep;

    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) {
        require(priceStep > 0, "Invalid price step");
        _asset1 = asset1Address;
        _asset2 = asset2Address;
        _priceStep = priceStep;
    }

    function getName()
        public
        view
        override(IInstrumentMetadata)
        returns (string memory)
    {
        string memory assetSym1 = IERC20Metadata(_asset1).symbol();
        string memory assetSym2 = IERC20Metadata(_asset2).symbol();
        return string(abi.encodePacked(assetSym1, "/", assetSym2));
    }

    function getStep()
        public
        view
        override(IInstrumentMetadata)
        returns (uint256)
    {
        return _priceStep;
    }

    function getFirstAssetAddress()
        public
        view
        override(IInstrumentMetadata)
        returns (address)
    {
        return _asset1;
    }

    function getSecondAssetAddress()
        public
        view
        override(IInstrumentMetadata)
        returns (address)
    {
        return _asset2;
    }

    function getMetadata()
        external
        view
        override(IInstrumentMetadata)
        returns (Metadata memory)
    {
        return Metadata(_asset1, _asset2, _priceStep, getName());
    }
}
