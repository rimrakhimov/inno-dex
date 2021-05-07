// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../../libraries/SharedOrderStructs.sol";

interface IInstrumentOrderBookAskable {
    function getOrder(bytes32 orderId) external view returns (Order memory);

    function getOrderBookRecords()
        external
        view
        returns (OrderBookRecord[] memory);

    function getOrderIds(address bidder)
        external
        view
        returns (bytes32[] memory);
}
