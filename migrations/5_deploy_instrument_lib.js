const Bytes32SetLib = artifacts.require("Bytes32SetLib");
const InstrumentOrderableLib = artifacts.require("InstrumentOrderableLib");

module.exports = function (deployer) {
    InstrumentOrderableLib.link(Bytes32SetLib);

    return deployer.deploy(InstrumentOrderableLib);
};