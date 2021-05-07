const Bytes32SetLib = artifacts.require("Bytes32SetLib");
const IterableSortedUintToBytes32SetMapping = artifacts.require("IterableSortedUintToBytes32SetMapping");

module.exports = function (deployer) {
    deployer.deploy(Bytes32SetLib).then(function () {
        IterableSortedUintToBytes32SetMapping.link("Bytes32SetLib", Bytes32SetLib.address);
        return deployer.deploy(IterableSortedUintToBytes32SetMapping);
    });
};