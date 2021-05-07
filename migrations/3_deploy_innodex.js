const InnoDex = artifacts.require("InnoDex");

module.exports = function (deployer) {
    deployer.deploy(InnoDex);
}