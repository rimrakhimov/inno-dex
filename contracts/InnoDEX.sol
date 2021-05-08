// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./instrument/interfaces/IInstrument.sol";
import "./ERC20/extensions/IERC20Metadata.sol";
import "./utils/Ownable.sol";
import "./utils/Context.sol";

contract InnoDex is Context, Ownable {
    struct InstrumentInternal {
        address contractAddress;
        uint256 index;
    }

    mapping(bytes32 => InstrumentInternal) private _instrumentBySymbols;
    mapping(address => address) private _ownerByInstrument;

    bytes32[] private _instrumentSymbols;

    uint256 public fee;

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

    event Withdrawal(address indexed src, uint256 wad);

    constructor(uint256 fee_) {
        fee = fee_;
    }

    // returns zero address if no such instrument exists
    function getInstrument(string calldata assetSym1, string calldata assetSym2)
        external
        view
        returns (address)
    {
        bytes32 h = _getHashBySymbols(assetSym1, assetSym2);
        return _instrumentBySymbols[h].contractAddress;
    }

    function getAllInstruments() external view returns (address[] memory) {
        uint256 count = _instrumentSymbols.length;
        address[] memory instruments = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            instruments[i] = _instrumentBySymbols[_instrumentSymbols[i]]
                .contractAddress;
        }
        return instruments;
    }

    function addInstrument(address instrument)
        external
        payable
        returns (address)
    {
        if (_msgSender() != owner()) {
            require(msg.value >= fee, "Not enough fee");
        }
        string memory sym1 =
            IERC20Metadata(IInstrument(instrument).getFirstAssetAddress())
                .symbol();
        string memory sym2 =
            IERC20Metadata(IInstrument(instrument).getSecondAssetAddress())
                .symbol();

        bytes32 h = _getHashBySymbols(sym1, sym2);
        bytes32 h2 = _getHashBySymbols(sym2, sym1);
        require(
            !_instrumentExists(h) && !_instrumentExists(h2),
            "Instrument with specified assets already exists"
        );

        _instrumentBySymbols[h].contractAddress = instrument;
        _instrumentBySymbols[h].index = _instrumentSymbols.length;
        _instrumentSymbols.push(h);
        _ownerByInstrument[instrument] = msg.sender;

        emit InstrumentAdded(sym1, sym2, instrument, msg.sender);
        return instrument;
    }

    function removeInstrument(address instrAddr) external {
        require(
            _instrumentExists(instrAddr),
            "Specified instrument does not exist"
        );
        require(
            _msgSender() == _ownerByInstrument[instrAddr],
            "Specified instrument does not belong to msg sender"
        );

        string memory sym1 =
            IERC20Metadata(IInstrument(instrAddr).getFirstAssetAddress())
                .symbol();
        string memory sym2 =
            IERC20Metadata(IInstrument(instrAddr).getSecondAssetAddress())
                .symbol();
        bytes32 h = _getHashBySymbols(sym1, sym2);

        uint256 indexToRemove = _instrumentBySymbols[h].index;
        uint256 lastElementIndex = _instrumentSymbols.length - 1;

        bytes32 lastElementSymbols = _instrumentSymbols[lastElementIndex];

        _swapInstrumentSymbolsElements(indexToRemove, lastElementIndex);
        _instrumentSymbols.pop();

        _instrumentBySymbols[lastElementSymbols].index = indexToRemove;

        delete (_instrumentBySymbols[h]);
        delete (_ownerByInstrument[instrAddr]);

        emit InstrumentRemoved(sym1, sym2, instrAddr);
    }

    function withdraw() external onlyOwner {
        uint256 value = address(this).balance;
        payable(_msgSender()).transfer(value);
        emit Withdrawal(_msgSender(), value);
    }

    /******************************** private ********************************/

    function _getHashBySymbols(string memory sym1, string memory sym2)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sym1, sym2));
    }

    function _instrumentExists(bytes32 h) private view returns (bool) {
        return _instrumentBySymbols[h].contractAddress != address(0);
    }

    function _instrumentExists(address contractAddr)
        private
        view
        returns (bool)
    {
        return _ownerByInstrument[contractAddr] != address(0);
    }

    function _swapInstrumentSymbolsElements(uint256 i, uint256 j) private {
        bytes32 iSymbol = _instrumentSymbols[i];
        bytes32 jSymbol = _instrumentSymbols[j];

        _instrumentSymbols[i] = jSymbol;
        _instrumentSymbols[j] = iSymbol;
    }
}
