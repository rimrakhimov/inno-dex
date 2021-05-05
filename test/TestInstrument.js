const ERC20 = artifacts.require("ERC20Mintable");
// const Asset2 = artifacts.require("ERC20Mintable");
const Instrument = artifacts.require("Instrument");

const priceStep = 1;

let asset1Instance;
let asset2Instance;
let instrumentInstance;

contract("Instrument test", async accounts => {
    beforeEach(async () => {
        asset1Instance = await ERC20.new("Test1", "TST1");
        asset2Instance = await ERC20.new("Test2", "TST2");
        instrumentInstance = await Instrument.new(Asset1Instance.address, Asset2Instance.address, priceStep);
        // assert.ok(ContractInstance)
    
        // erc20factoryInstance = await erc20factory.new()
        // await ContractInstance.setParent(erc20factoryInstance.address)

        let t = await asset1Instance.symbol.call();
        assert.equal(t, "TST1", "Invalid symbol");
    });

    it("should return valid instrument name", async () => {
        let t = asset1Instance.symbol().call();
        // assert.equal(t, "TST1", "Invalid symbol");
        // const instance = await MetaCoin.deployed();
        // const balance = await instance.getBalance.call(accounts[0]);
        // assert.equal(balance.valueOf(), 10000);
    });
});