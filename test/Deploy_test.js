/* eslint-disable no-unused-expressions */
const { accounts, contract } = require('@openzeppelin/test-environment');

const { expectRevert, singletons } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Squarrin = contract.fromArtifact('Squarrin');
const Quadreum = contract.fromArtifact('Quadreum');

describe('Deployment initialization testing', async function () {
  const [owner, registryFunder] = accounts;
  beforeEach(async function () {
    this.squarrin = await Squarrin.new(5, { from: owner });
    const defaultOperator = [this.squarrin.address];
    this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    this.quadreum = await Quadreum.new(owner, defaultOperator, { from: owner });
  });

  it('Quadreum contract set its address in Squarrin contract', async function () {
    expect(await this.squarrin.getQuadreum()).to.equal(this.quadreum.address);
  });

  it('Squarrin reverts if Quadreum address is set twice', async function () {
    await expectRevert(this.squarrin.setQuadreum(), 'Squarrin: Quadreum address is already set');
  });
});
