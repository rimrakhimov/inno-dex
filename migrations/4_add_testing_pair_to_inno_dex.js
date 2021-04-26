const InnoDex = artifacts.require("InnoDex");
const ERC20 = artifacts.require("ERC20Basic");

const WETHAddress = "0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5";
const defaultPriceStep = 1000;

module.exports = async (deployer) => {
    InnoDexInstance = await InnoDex.deployed();
    ERC20Instance = await ERC20.deployed();
    await InnoDexInstance.addInstrument(ERC20Instance.address, WETHAddress, defaultPriceStep);
}