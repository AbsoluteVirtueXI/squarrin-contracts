const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectRevert, singletons } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Squarrin = contract.fromArtifact('Squarrin');
const Quadreum = contract.fromArtifact('Quadreum');

describe('Quadreum', () => {
  const [dev, owner, registryFunder, addr1, addr2] = accounts;
  const TOTAL_SUPPLY = new BN('8' + '0'.repeat(27));
  const NAME = 'Quadreum';
  const SYMBOL = 'QUAD';

  context('Quadreum without only 1 default operator', function () {
    beforeEach(async function () {
      this.squarrin = await Squarrin.new(5, { from: dev });
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    it('Quadreum reverts if no default operators at deployment', async function () {
      await expectRevert(Quadreum.new(owner, [], { from: dev }), 'Quadreum: Only one default operator is allowed');
    });

    it('Quadreum reverts if more than 1 default operators at deployment', async function () {
      await expectRevert(
        Quadreum.new(owner, [this.squarrin.address, addr1], { from: dev }),
        'Quadreum: Only one default operator is allowed',
      );
    });
  });

  context('Quadreum with a successful deployment', function () {
    beforeEach(async function () {
      this.squarrin = await Squarrin.new(5, { from: dev });
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      this.defaultOperators = [this.squarrin.address];
      this.quadreum = await Quadreum.new(owner, this.defaultOperators, { from: dev });
    });

    it(`has name ${NAME}`, async function () {
      expect(await this.quadreum.name()).to.equal(NAME);
    });

    it(`has symbol ${SYMBOL}`, async function () {
      expect(await this.quadreum.symbol()).to.equal(SYMBOL);
    });

    it(`has total supply of ${TOTAL_SUPPLY.toString()}`, async function () {
      expect(await this.quadreum.totalSupply()).to.be.a.bignumber.equal(TOTAL_SUPPLY);
    });

    it('has Squarrin contract as only one default operator', async function () {
      expect((await this.quadreum.defaultOperators()).length, 'There are more than 1 default operator').to.equal(1);
      expect((await this.quadreum.defaultOperators())[0], 'Squarrin address is invalid').to.equal(
        this.squarrin.address,
      );
    });

    it('has registered itself in Squarrin contract', async function () {
      expect(await this.squarrin.getQuadreum()).to.equal(this.quadreum.address);
    });

    it('has an owner', async function () {
      expect(await this.quadreum.owner()).to.equal(owner);
    });

    it('sends total supply to owner', async function () {
      expect(await this.quadreum.balanceOf(owner)).to.be.bignumber.equal(TOTAL_SUPPLY);
    });

    it('reverts on Squarrin if a second Quadreum contract is deployed', async function () {
      await expectRevert(
        Quadreum.new(owner, this.defaultOperators, { from: dev }),
        'Squarrin: Quadreum address is already set',
      );
    });
  });
});
