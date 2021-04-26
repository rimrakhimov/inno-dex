const InnoDex = artifacts.require("InnoDex");
const ERC20 = artifacts.require("ERC20Basic");

const WETHAddress = "0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5";
const defaultPriceStep = 1000;

module.exports = function(deployer) {
    return deployer.deploy(InnoDex);
}
