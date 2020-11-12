const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, singletons } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Quadreum = contract.fromArtifact('Quadreum');
const Squarrin = contract.fromArtifact('Squarrin');

describe('Quadreum', () => {
  const [owner, registryFunder] = accounts;
  const TOTAL_SUPPLY = new BN('8' + '0'.repeat(27));
  const NAME = 'Quadreum';
  const SYMBOL = 'QUAD';
  beforeEach(async function () {
    this.squarrin = await Squarrin.new(5, { from: owner });
    const defaultOperators = [this.squarrin.address];
    this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    this.quadreum = await Quadreum.new(owner, defaultOperators, { from: owner });
  });

  it('has name Quadreum', async function () {
    expect(await this.quadreum.name()).to.equal(NAME);
  });

  it('has symbol QUAD', async function () {
    expect(await this.quadreum.symbol()).to.equal(SYMBOL);
  });

  it('sends total supply to owner', async function () {
    expect(await this.quadreum.balanceOf(owner)).to.be.bignumber.equal(TOTAL_SUPPLY);
  });

  it('has an owner', async function () {
    expect(await this.quadreum.getOwner()).to.equal(owner);
  });

  it('has Squarrin address contract', async function () {
    expect(await this.quadreum.getSquarrin()).to.equal(this.squarrin.address);
  });

  it('set Quadreum address in Squarrin contract', async function () {
    expect(await this.squarrin.getQuadreum()).to.equal(this.quadreum.address);
  });

  it('has Squarrin contract as only one default operator', async function () {
    expect((await this.quadreum.defaultOperators()).length, 'There are more than 1 default operator').to.equal(1);
    expect((await this.quadreum.defaultOperators())[0], 'Squarrin address is invalid').to.equal(this.squarrin.address);
  });
});
