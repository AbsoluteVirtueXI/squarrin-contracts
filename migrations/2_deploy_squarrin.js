const Squarrin = artifacts.require('Squarrin');

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Squarrin, accounts[0], 5);
};
