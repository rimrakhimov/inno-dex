const ERC20 = artifacts.require("ERC20Suppliable");
const Instrument = artifacts.require("Instrument");

const maxUint = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1));

const sellPrice = web3.utils.toBN(10).pow(web3.utils.toBN(13));
const sellQty = web3.utils.toBN(10).pow(web3.utils.toBN(5)).mul(web3.utils.toBN(5000));

module.exports = async function (deployer) {
    let erc20Instance = await ERC20.deployed();
    let instrumentInstance = await Instrument.deployed();

    await erc20Instance.approve(instrumentInstance.address, maxUint);
    await instrumentInstance.limitOrder(false, sellPrice, sellQty, 0);
}