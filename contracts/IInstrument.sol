// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./libraries/SharedOrderStructs.sol";

interface IInstrument {
    struct Metadata {
        address firstAssetAddress;
        address secondAssetAddress;
        uint256 step;
        string name;
    }

    function getName() external view returns (string memory);

    function getStep() external view returns (uint256);

    function getFirstAssetAddress() external view returns (address);

    function getSecondAssetAddress() external view returns (address);

    function getMetadata() external view returns (Metadata memory);

    function limitOrder(
        OrderType orderType,
        uint256 price,
        uint256 qty,
        uint256 flags
    ) external returns (bytes32);

    function marketOrder(OrderType orderType, uint256 qty) external;

    function cancelOrder(bytes32 id) external;

    event OrderPlaced(
        address indexed bidder,
        bytes32 orderId,
        OrderType orderType,
        uint256 price,
        uint256 qty
    );
    event OrderPartiallyExecuted(bytes32 indexed orderId, uint256 qty, uint256 price);
    event OrderExecuted(bytes32 orderId);

    event SpotPriceChanged(OrderType orderBookType, uint256 newPrice);
}
