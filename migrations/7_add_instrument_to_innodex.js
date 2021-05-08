const InnoDex = artifacts.require("InnoDex");
const Instrument = artifacts.require("Instrument");

module.exports = async function (deployer) {
    let innoDexInstance = await InnoDex.deployed();
    let instrumentInstance = await Instrument.deployed();

    return innoDexInstance.addInstrument(instrumentInstance.address);
}