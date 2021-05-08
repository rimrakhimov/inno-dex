const InnoDex = artifacts.require("InnoDex");

const fee = web3.utils.toWei('3', 'ether');

module.exports = function (deployer) {
    deployer.deploy(InnoDex, fee);
}