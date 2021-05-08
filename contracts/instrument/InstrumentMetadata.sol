// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IInstrumentMetadata.sol";
import "./InstrumentStorage.sol";
import "../ERC20/extensions/IERC20Metadata.sol";

abstract contract InstrumentMetadata is IInstrumentMetadata, InstrumentStorage {
    constructor(
        address asset1Address,
        address asset2Address,
        uint256 priceStep
    ) {
        require(priceStep > 0, "Invalid price step");
        setAsset1(asset1Address);
        setAsset2(asset2Address);
        setPriceStep(priceStep);
    }

    function getName()
        public
        view
        override(IInstrumentMetadata)
        returns (string memory)
    {
        string memory assetSym1 = IERC20Metadata(getAsset1()).symbol();
        string memory assetSym2 = IERC20Metadata(getAsset2()).symbol();
        return string(abi.encodePacked(assetSym1, "/", assetSym2));
    }

    function getStep()
        public
        view
        override(IInstrumentMetadata)
        returns (uint256)
    {
        return getPriceStep();
    }

    function getFirstAssetAddress()
        public
        view
        override(IInstrumentMetadata)
        returns (address)
    {
        return getAsset1();
    }

    function getSecondAssetAddress()
        public
        view
        override(IInstrumentMetadata)
        returns (address)
    {
        return getAsset2();
    }

    function getMetadata()
        external
        view
        override(IInstrumentMetadata)
        returns (Metadata memory)
    {
        return
            Metadata(
                getFirstAssetAddress(),
                getSecondAssetAddress(),
                getStep(),
                getName()
            );
    }
}
