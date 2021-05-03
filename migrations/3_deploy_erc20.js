const ERC20 = artifacts.require("ERC20Mintable");

const name = "Test1";
const symbol = "TST1";

module.exports = async (deployer) => {
    deployer.deploy(ERC20, name, symbol);
}