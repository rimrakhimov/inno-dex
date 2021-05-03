pragma solidity >= 0.8.0;

import "truffle/Assert.sol";
import "../contracts/ERC20/extensions/ERC20Mintable.sol";
import "../contracts/InstrumentDefault.sol";

contract TestInstrument {
    ERC20Mintable asset1;
    ERC20Mintable asset2;
    Instrument instrument;

    function beforeEachDeployTokens() external {
        asset1 = new ERC20Mintable("Test1", "TST1");
        asset2 = new ERC20Mintable("Test2", "TST2");
    }

    function beforeEachRequestTokens() external {
        asset1.requestTokens(); asset1.requestTokens(); asset1.requestTokens();
        asset2.requestTokens(); asset2.requestTokens(); asset2.requestTokens(); 
    }

    function beforeEachDeployInstrument() external {
        instrument = new Instrument(address(asset1), address(asset2), 1);
    }

    function testGetName() external {
        Assert.equal(asset1.symbol(), "TST1", "Invalid symbol for first asset");
        Assert.equal(asset2.symbol(), "TST2", "Invalid symbol for first asset");
        // Assert.equal(instrument.getName(), "TST1/TST2", "Invalid name");
    }
}