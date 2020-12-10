/* eslint-disable no-unused-expressions */
const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectRevert, singletons, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Squarrin = contract.fromArtifact('Squarrin');
const Quadreum = contract.fromArtifact('Quadreum');

/*
it('reverts if Quadreum address is set twice in Squarrin contract', async function () {
  await expectRevert(this.squarrin.setQuadreum(), 'Squarrin: Quadreum address is already set');
});
*/

const _isSameUser = (user1, user2) => {
  return (
    user1.isContentCreator === user2.isContentCreator &&
    new BN(user1.nbFollowers).eq(user2.nbFollowers) &&
    new BN(user1.nbFollowings).eq(user2.nbFollowings) &&
    new BN(user1.createdAt).eq(user2.createdAt)
  );
};

describe('Squarrin', function () {
  const [dev, owner, registryFunder, user1, user2, user3, user4, admin1, admin2] = accounts;
  const TOTAL_SUPPLY = new BN('8' + '0'.repeat(27));
  const NAME = 'Quadreum';
  const SYMBOL = 'QUAD';
  const MIN_PERCENTAGE = new BN(0);
  const MAX_PERCENTAGE = new BN(100);
  const PERCENTAGE = new BN(5);
  const DEFAULT_MIN_FOLLOWING_TIME_FOR_REWARD = time.duration.weeks(4);
  context('Squarrin with failed deployment', function () {
    it(`reverts if percentage is not between ${MIN_PERCENTAGE} and ${MAX_PERCENTAGE}`, async function () {
      await expectRevert(Squarrin.new(admin1, 101, { from: dev }), 'Squarrin: Invalid percentage number');
    });
  });

  context('Squarrin with succesful deployment', function () {
    context('Squarrin initial state', function () {
      beforeEach(async function () {
        this.squarrin = await Squarrin.new(admin1, PERCENTAGE, { from: dev });
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
        this.defaultOperators = [this.squarrin.address];
        this.quadreum = await Quadreum.new(owner, this.defaultOperators, { from: dev });
      });

      it('has a minimum following time for reward', async function () {
        expect(await this.squarrin.followingTimeForReward()).to.be.a.bignumber.equal(
          DEFAULT_MIN_FOLLOWING_TIME_FOR_REWARD,
        );
      });
      it('has id 0 for last product at deployment', async function () {
        expect(await this.squarrin.lastProductId()).to.be.a.bignumber.equal(new BN(0));
      });

      it('has admin at deployment', async function () {
        expect(await this.squarrin.isAdmin(admin1)).to.be.true;
      });

      it(`has percentage == ${PERCENTAGE}`, async function () {
        expect(await this.squarrin.rewardPercentage()).to.be.a.bignumber.equal(PERCENTAGE);
      });

      it('has Quadreum address', async function () {
        expect(await this.squarrin.getQuadreum()).to.equal(this.quadreum.address);
      });

      it('reverts if quadreum address is set more than once', async function () {
        await expectRevert(
          this.squarrin.setQuadreum({ from: this.quadreum.address }),
          'Squarrin: Quadreum address is already set',
        );
      });
    });

    context('Squarrin registration', function () {
      beforeEach(async function () {
        this.squarrin = await Squarrin.new(admin1, PERCENTAGE, { from: dev });
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
        this.defaultOperators = [this.squarrin.address];
        this.quadreum = await Quadreum.new(owner, this.defaultOperators, { from: dev });
      });

      it('registers user', async function () {
        await this.squarrin.register(user1, true, { from: admin1 });
        await this.squarrin.register(user2, false, { from: admin1 });
      });

      it('reverts if register is not called by an admin', async function () {
        await expectRevert(
          this.squarrin.register(user1, true, { from: dev }),
          'Squarrin: Only administrators can do this',
        );
      });

      it('reverts if it registers same user twice', async function () {
        await this.squarrin.register(user1, true, { from: admin1 });
        await expectRevert(
          this.squarrin.register(user1, true, { from: admin1 }),
          'Squarrin: User is already registered',
        );
      });

      it('can get registered user informations', async function () {
        await this.squarrin.register(user1, true, { from: admin1 });
        const _t1 = await time.latest();
        const _user1 = await this.squarrin.getUser(user1);
        expect(
          _isSameUser(_user1, {
            isContentCreator: true,
            nbFollowers: new BN(0),
            nbFollowings: new BN(0),
            createdAt: _t1,
          }),
          'registered user1 do not have expected informations',
        ).to.be.true;
        await this.squarrin.register(user2, false, { from: admin1 });
        const _t2 = await time.latest();
        const _user2 = await this.squarrin.getUser(user2);
        expect(
          _isSameUser(_user2, {
            isContentCreator: false,
            nbFollowers: new BN(0),
            nbFollowings: new BN(0),
            createdAt: _t2,
          }),
          'registred user2 do not have expected informations',
        ).to.be.true;
        expect(_isSameUser(_user1, _user2), 'user1 and user2 should not have same informations').to.be.false;
      });

      it('reverts if it get unregistered user informations', async function () {
        await expectRevert(this.squarrin.getUser(user1), 'Squarrin: User is not registered');
      });

      it('can set content creators', async function () {
        await this.squarrin.register(user1, false, { from: admin1 });
        await this.squarrin.setContentCreator(user1, true, { from: admin1 });
        const _user1 = await this.squarrin.getUser(user1);
        expect(_user1.isContentCreator).to.be.true;
      });

      it('reverts if content cretors set on unregistered user', async function () {
        await expectRevert(
          this.squarrin.setContentCreator(user1, true, { from: admin1 }),
          'Squarrin: User is not registered',
        );
      });

      it('reverts if setContentCreator is not called by admin', async function () {
        await this.squarrin.register(user1, false, { from: admin1 });

        await expectRevert(
          this.squarrin.setContentCreator(user1, true, { from: dev }),
          'Squarrin: Only administrators can do this',
        );
      });
    });
    context('Squarrin following system', function () {
      beforeEach(async function () {
        this.squarrin = await Squarrin.new(admin1, PERCENTAGE, { from: dev });
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
        this.defaultOperators = [this.squarrin.address];
        this.quadreum = await Quadreum.new(owner, this.defaultOperators, { from: dev });
        await this.squarrin.register(user1, false, { from: admin1 });
        await this.squarrin.register(user2, true, { from: admin1 });
        await this.squarrin.register(user3, false, { from: admin1 });
        await this.squarrin.register(user4, false, { from: admin1 });
      });

      it('can follow users', async function () {
        await this.squarrin.follow(user1, user2, { from: admin1 });
        const status1 = await this.squarrin.isFollowing(user1, user2);
        const t1 = await time.latest();
        expect(status1.isFollowing).to.be.true;
        expect(status1.followingDate).to.be.a.bignumber.equal(t1);
        await this.squarrin.follow(user2, user3, { from: admin1 });
        const status2 = await this.squarrin.isFollowing(user2, user3);
        const t2 = await time.latest();
        expect(status2.isFollowing).to.be.true;
        expect(status2.followingDate).to.be.a.bignumber.equal(t2);
        await this.squarrin.follow(user1, user3, { from: admin1 });
        const status3 = await this.squarrin.isFollowing(user1, user3);
        const t3 = await time.latest();
        expect(status3.isFollowing).to.be.true;
        expect(status3.followingDate).to.be.a.bignumber.equal(t3);
        const status4 = await this.squarrin.isFollowing(user3, user2, { from: admin1 });
        expect(status4.isFollowing).to.be.false;
        expect(status4.followingDate).to.be.a.bignumber.equal(new BN(0));
      });

      it('increases nbFollowers and nbFollowings when follow', async function () {
        let _user1 = await this.squarrin.getUser(user1);
        expect(_user1.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user1.nbFollowings).to.be.a.bignumber.equal(new BN(0));
        await this.squarrin.follow(user1, user2, { from: admin1 });
        await this.squarrin.follow(user1, user3, { from: admin1 });
        await this.squarrin.follow(user1, user4, { from: admin1 });
        await this.squarrin.follow(user2, user4, { from: admin1 });
        _user1 = await this.squarrin.getUser(user1);
        const _user2 = await this.squarrin.getUser(user2);
        const _user3 = await this.squarrin.getUser(user3);
        const _user4 = await this.squarrin.getUser(user4);
        expect(_user1.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user1.nbFollowings).to.be.a.bignumber.equal(new BN(3));
        expect(_user2.nbFollowers).to.be.a.bignumber.equal(new BN(1));
        expect(_user2.nbFollowings).to.be.a.bignumber.equal(new BN(1));
        expect(_user3.nbFollowers).to.be.a.bignumber.equal(new BN(1));
        expect(_user3.nbFollowings).to.be.a.bignumber.equal(new BN(0));
        expect(_user4.nbFollowers).to.be.a.bignumber.equal(new BN(2));
        expect(_user4.nbFollowings).to.be.a.bignumber.equal(new BN(0));
      });

      it('reverts if user1 follows an already followed user2', async function () {
        await this.squarrin.follow(user1, user2, { from: admin1 });
        await expectRevert(
          this.squarrin.follow(user1, user2, { from: admin1 }),
          'Squarrin: Only follow unfollowed user',
        );
      });

      it('reverts if follow is not called by admin', async function () {
        await expectRevert(
          this.squarrin.follow(user1, user2, { from: dev }),
          'Squarrin: Only administrators can do this',
        );
      });

      it('reverts if when follow, follower or following is not registered', async function () {
        await expectRevert(this.squarrin.follow(user1, dev, { from: admin1 }), 'Squarrin: User is not registered');
        await expectRevert(this.squarrin.follow(dev, user1, { from: admin1 }), 'Squarrin: User is not registered');
        await expectRevert(this.squarrin.follow(admin1, dev, { from: admin1 }), 'Squarrin: User is not registered');
      });
    });

    context('Squarrin unfollowing system', async function () {
      beforeEach(async function () {
        this.squarrin = await Squarrin.new(admin1, PERCENTAGE, { from: dev });
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
        this.defaultOperators = [this.squarrin.address];
        this.quadreum = await Quadreum.new(owner, this.defaultOperators, { from: dev });
        await this.squarrin.register(user1, false, { from: admin1 });
        await this.squarrin.register(user2, true, { from: admin1 });
        await this.squarrin.register(user3, false, { from: admin1 });
        await this.squarrin.register(user4, false, { from: admin1 });
        await this.squarrin.follow(user1, user2, { from: admin1 });
        await this.squarrin.follow(user1, user3, { from: admin1 });
        await this.squarrin.follow(user1, user4, { from: admin1 });
        await this.squarrin.follow(user2, user3, { from: admin1 });
      });

      it('can unfollow users', async function () {
        let status1 = await this.squarrin.isFollowing(user1, user2, { from: admin1 });
        expect(status1.isFollowing).to.be.true;
        await this.squarrin.unfollow(user1, user2, { from: admin1 });
        await this.squarrin.unfollow(user1, user3, { from: admin1 });
        await this.squarrin.unfollow(user1, user4, { from: admin1 });
        await this.squarrin.unfollow(user2, user3, { from: admin1 });
        status1 = await this.squarrin.isFollowing(user1, user2, { from: admin1 });
        const status2 = await this.squarrin.isFollowing(user1, user3, { from: admin1 });
        const status3 = await this.squarrin.isFollowing(user1, user4, { from: admin1 });
        const status4 = await this.squarrin.isFollowing(user2, user3, { from: admin1 });
        expect(status1.isFollowing).to.be.false;
        expect(status2.isFollowing).to.be.false;
        expect(status3.isFollowing).to.be.false;
        expect(status4.isFollowing).to.be.false;
      });

      it('decreases nbFollowers and nbFollowings when unfollow', async function () {
        let _user1 = await this.squarrin.getUser(user1);
        expect(_user1.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user1.nbFollowings).to.be.a.bignumber.equal(new BN(3));
        await this.squarrin.unfollow(user1, user2, { from: admin1 });
        await this.squarrin.unfollow(user1, user3, { from: admin1 });
        await this.squarrin.unfollow(user2, user3, { from: admin1 });
        _user1 = await this.squarrin.getUser(user1);
        const _user2 = await this.squarrin.getUser(user2);
        const _user3 = await this.squarrin.getUser(user3);
        const _user4 = await this.squarrin.getUser(user4);
        expect(_user1.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user1.nbFollowings).to.be.a.bignumber.equal(new BN(1));
        expect(_user2.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user2.nbFollowings).to.be.a.bignumber.equal(new BN(0));
        expect(_user3.nbFollowers).to.be.a.bignumber.equal(new BN(0));
        expect(_user3.nbFollowings).to.be.a.bignumber.equal(new BN(0));
        expect(_user4.nbFollowers).to.be.a.bignumber.equal(new BN(1));
        expect(_user4.nbFollowings).to.be.a.bignumber.equal(new BN(0));
      });

      it('reverts if user1 unfollows an already unfollowed user2', async function () {
        await this.squarrin.unfollow(user1, user2, { from: admin1 });
        await expectRevert(this.squarrin.unfollow(user1, user2, { from: admin1 }), 'Squarrin: Only unfollow following');
      });

      it('reverts if unfollow is not called by admin', async function () {
        await expectRevert(
          this.squarrin.unfollow(user1, user2, { from: dev }),
          'Squarrin: Only administrators can do this',
        );
      });

      it('reverts if when unfollow, follower or following is not registered', async function () {
        await expectRevert(this.squarrin.unfollow(user1, dev, { from: admin1 }), 'Squarrin: User is not registered');
        await expectRevert(this.squarrin.unfollow(dev, user1, { from: admin1 }), 'Squarrin: User is not registered');
        await expectRevert(this.squarrin.unfollow(admin1, dev, { from: admin1 }), 'Squarrin: User is not registered');
      });
    });
    context('Squarrin sell/buy system', async function () {});
    context('Squarrin reward system', async function () {});
  });
});
