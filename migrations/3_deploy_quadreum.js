const Quadreum = artifacts.require('Quadreum');
const Squarrin = artifacts.require('Squarrin');

module.exports = async function (deployer) {
  const squarrin = await Squarrin.deployed();
  await deployer.deploy(Quadreum, '0x7Ef41ddA7283CF71C02472FF1C92bD28657f7670', [squarrin.address]);
};
