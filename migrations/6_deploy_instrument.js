const ERC20 = artifacts.require("ERC20Suppliable");
const WETH = artifacts.require("WETH");

const Bytes32SetLib = artifacts.require("Bytes32SetLib");
const IterableSortedUintToBytes32SetMapping = artifacts.require("IterableSortedUintToBytes32SetMapping");
const InstrumentOrderableLib = artifacts.require("InstrumentOrderableLib");

const Instrument = artifacts.require("Instrument");

const ropstenWethAddress = '0xc778417E063141139Fce010982780140Aa0cD5Ab';

const priceStep = web3.utils.toBN(10).pow(web3.utils.toBN(8));

module.exports = async function (deployer, network) {
    let erc20Instance = await ERC20.deployed();

    Instrument.link(Bytes32SetLib);
    Instrument.link(IterableSortedUintToBytes32SetMapping);
    Instrument.link(InstrumentOrderableLib);

    if (network == 'ropsten') {
        return deployer.deploy(Instrument, erc20Instance.address, ropstenWethAddress, priceStep);
    } else {
        let wethInstance = await WETH.deployed();
        return deployer.deploy(Instrument, erc20Instance.address, wethInstance.address, priceStep);
    }
}