const Squarrin = artifacts.require('Squarrin');

module.exports = async function (deployer) {
  await deployer.deploy(Squarrin, 5);
};
