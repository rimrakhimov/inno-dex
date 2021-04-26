const ERC20 = artifacts.require("ERC20Basic");

module.exports = function(deployer) {
    return deployer.deploy(ERC20, "TestToken1", "TST1", 1000000);
}
