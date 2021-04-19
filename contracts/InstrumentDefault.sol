pragma solidity ^0.8.3;

import "./IInstrument.sol";


contract InstrumentDefault is IInstrument {
    constructor(address asset1, address asset2, uint priceStep) public {
        
    }

    function getName() external override(IInstrument) view returns (string memory) {
        return "";
    }

    function getStep() external override(IInstrument) view returns (uint) {
        return 0;
    }

    function getFirstAssetAddress() external override(IInstrument) view returns (address) {
        return address(0);
    }
    
    function getSecondAssetAddress() external override(IInstrument) view returns (address) {
        return address(0);
    }
    
    function getMetadata() external override(IInstrument) view returns (Metadata memory) {
        return Metadata(address(0), address(0), 0, "");
    }
    
    function limitOrder(OrderType orderType, uint price, uint qty, uint flags) 
        external override(IInstrument) returns (bytes32) 
    {
        return bytes32(0);
    }

    function marketOrder(OrderType orderType, uint qty) external override(IInstrument) {
        return;
    }

    function cancelOrder(bytes32 id) external override(IInstrument) {
        return;
    }
}
