pragma solidity ^0.8.3;


interface IInstrument {
    enum OrderType {
        Buy,
        Sell
    }

    struct Metadata {
        address firstAssetAddress;
        address secondAssetAddress;
        uint step;
        string name;
    }

    function getName() external view returns (string memory);
    function getStep() external view returns (uint);
    function getFirstAssetAddress() external view returns (address);
    function getSecondAssetAddress() external view returns (address);
    function getMetadata() external view returns (Metadata memory);
    
    function limitOrder(OrderType orderType, uint price, uint qty, uint flags) external returns (bytes32);
    function marketOrder(OrderType orderType, uint qty) external;
    function cancelOrder(bytes32 id) external;
}