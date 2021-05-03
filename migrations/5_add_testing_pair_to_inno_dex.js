const InnoDex = artifacts.require("InnoDex");
const Instrument = artifacts.require("Instrument");

module.exports = async (deployer) => {
    InnoDexInstance = await InnoDex.deployed();
    InstrumentInstance = await Instrument.deployed();
    await InnoDexInstance.addInstrument(InstrumentInstance.address);
}