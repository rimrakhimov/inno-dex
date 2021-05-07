// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../../libraries/SharedOrderStructs.sol";

interface IInstrumentOrderable {
    function limitOrder(
        bool toBuy,
        uint256 price,
        uint256 qty,
        uint256 flags
    ) external returns (bytes32);

    function marketOrder(bool toBuy, uint256 qty) external returns (bytes32);

    function cancelOrder(bytes32 id) external;

    event OrderPlaced(
        address indexed bidder,
        bytes32 orderId,
        OrderType orderType,
        uint256 price,
        uint256 qty
    );

    event SpotPriceChanged(OrderType orderBookType, uint256 newPrice);
    event OrderCancelled(bytes32 orderId);
    event OrderExecuted(bytes32 orderId);
    event OrderPartiallyExecuted(
        bytes32 indexed orderId,
        uint256 qty,
        uint256 price
    );
}
