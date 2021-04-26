pragma solidity ^0.8.3;

import "./IInstrument.sol";
import "./ERC20/IERC20Metadata.sol";

contract Instrument is IInstrument {
    IERC20Metadata asset1;
    IERC20Metadata asset2;
    uint256 priceStep;

    constructor(
        address _asset1Address,
        address _asset2Address,
        uint256 _priceStep
    ) {
        asset1 = IERC20Metadata(_asset1Address);
        asset2 = IERC20Metadata(_asset2Address);
        priceStep = _priceStep;
    }

    function getName()
        public
        view
        override(IInstrument)
        returns (string memory)
    {
        string memory assetSym1 = asset1.symbol();
        string memory assetSym2 = asset2.symbol();
        return string(abi.encodePacked(assetSym1, "/", assetSym2));
    }

    function getStep() external view override(IInstrument) returns (uint256) {
        return priceStep;
    }

    function getFirstAssetAddress()
        external
        view
        override(IInstrument)
        returns (address)
    {
        return address(asset1);
    }

    function getSecondAssetAddress()
        external
        view
        override(IInstrument)
        returns (address)
    {
        return address(asset2);
    }

    function getMetadata()
        external
        view
        override(IInstrument)
        returns (Metadata memory)
    {
        return Metadata(address(asset1), address(asset2), priceStep, getName());
    }

    function limitOrder(
        OrderType orderType,
        uint256 price,
        uint256 qty,
        uint256 flags
    ) external override(IInstrument) returns (bytes32) {
        return bytes32(0);
    }

    function marketOrder(OrderType orderType, uint256 qty)
        external
        override(IInstrument)
    {
        return;
    }

    function cancelOrder(bytes32 id) external override(IInstrument) {
        return;
    }
}
