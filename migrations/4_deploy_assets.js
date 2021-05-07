const WETH = artifacts.require("WETH");
const ERC20 = artifacts.require("ERC20Suppliable");

const decimals = web3.utils.toBN(5);
const totalSupply = web3.utils.toBN(10).pow(web3.utils.toBN(5)).mul(web3.utils.toBN(10000));

module.exports = function (deployer, network) {
    if (network != 'ropsten') {
        deployer.deploy(WETH);
    }

    deployer.deploy(ERC20, "InnoCoin", "INC", decimals, totalSupply);
}