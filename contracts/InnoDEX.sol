// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./instrument/IInstrument.sol";
import "./ERC20/extensions/IERC20Metadata.sol";

contract InnoDex {
    struct InstrumentInternal {
        address contractAddress;
        uint256 index;
    }

    mapping(bytes32 => InstrumentInternal) instrumentBySymbols;
    mapping(address => address) ownerByInstrument;

    bytes32[] instrumentSymbols;

    event InstrumentAdded(
        string indexed assetSym1,
        string indexed assetSym2,
        address contractAddress,
        address owner
    );

    event InstrumentRemoved(
        string indexed assetSym1,
        string indexed assetSym2,
        address contractAddress
    );

    // returns zero address if no such instrument exists
    function getInstrument(string calldata assetSym1, string calldata assetSym2)
        external
        view
        returns (address)
    {
        bytes32 h = getHashBySymbols(assetSym1, assetSym2);
        return instrumentBySymbols[h].contractAddress;
    }

    function getAllInstruments() external view returns (address[] memory) {
        uint256 count = instrumentSymbols.length;
        address[] memory instruments = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            instruments[i] = instrumentBySymbols[instrumentSymbols[i]]
                .contractAddress;
        }
        return instruments;
    }

    function addInstrument(
        address instrument
    ) external returns (address) {
        string memory sym1 = IERC20Metadata(IInstrument(instrument).getFirstAssetAddress()).symbol();
        string memory sym2 = IERC20Metadata(IInstrument(instrument).getSecondAssetAddress()).symbol();

        bytes32 h = getHashBySymbols(sym1, sym2);
        bytes32 h2 = getHashBySymbols(sym2, sym1);
        require(
            !instrumentExists(h) && !instrumentExists(h2),
            "Instrument with specified assets already exists"
        );

        instrumentBySymbols[h].contractAddress = instrument;
        instrumentBySymbols[h].index = instrumentSymbols.length;
        instrumentSymbols.push(h);
        ownerByInstrument[instrument] = msg.sender;

        emit InstrumentAdded(sym1, sym2, instrument, msg.sender);
        return instrument;
    }

    function removeInstrument(address instrAddr) external {
        require(
            instrumentExists(instrAddr),
            "Specified instrument does not exist"
        );

        string memory sym1 =
            IERC20Metadata(IInstrument(instrAddr).getFirstAssetAddress())
                .symbol();
        string memory sym2 =
            IERC20Metadata(IInstrument(instrAddr).getSecondAssetAddress())
                .symbol();
        bytes32 h = getHashBySymbols(sym1, sym2);

        uint256 indexToRemove = instrumentBySymbols[h].index;
        uint256 lastElementIndex = instrumentSymbols.length - 1;

        bytes32 lastElementSymbols = instrumentSymbols[lastElementIndex];

        swapInstrumentSymbolsElements(indexToRemove, lastElementIndex);
        instrumentSymbols.pop();

        instrumentBySymbols[lastElementSymbols].index = indexToRemove;

        delete (instrumentBySymbols[h]);
        delete (ownerByInstrument[instrAddr]);

        emit InstrumentRemoved(sym1, sym2, instrAddr);
    }

    function getHashBySymbols(string memory sym1, string memory sym2)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sym1, sym2));
    }

    function instrumentExists(bytes32 h) private view returns (bool) {
        return instrumentBySymbols[h].contractAddress != address(0);
    }

    function instrumentExists(address contractAddr)
        private
        view
        returns (bool)
    {
        return ownerByInstrument[contractAddr] != address(0);
    }

    function swapInstrumentSymbolsElements(uint256 i, uint256 j) private {
        bytes32 iSymbol = instrumentSymbols[i];
        bytes32 jSymbol = instrumentSymbols[j];

        instrumentSymbols[i] = jSymbol;
        instrumentSymbols[j] = iSymbol;
    }
}
