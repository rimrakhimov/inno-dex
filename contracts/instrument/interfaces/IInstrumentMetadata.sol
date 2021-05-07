// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IInstrumentMetadata {
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
}
