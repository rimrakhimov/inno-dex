const InnoDex = artifacts.require("InnoDex");

const TST1Address = "0xFE184DB9F97Bd46bE7b9CeC1D7588efd8f4e7273";
const WETHAddress = "0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5";
const defaultPriceStep = 1000;

module.exports = async (deployer) => {
    InnoDexInstance = await InnoDex.deployed();
    await InnoDexInstance.addInstrument(TST1Address, WETHAddress, defaultPriceStep);
}