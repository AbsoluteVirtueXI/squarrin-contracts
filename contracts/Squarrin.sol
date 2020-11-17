// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./Quadreum.sol";

contract Squarrin {
    struct User {
        bool isContentCreator;
        uint256 nbFollowers;
        uint256 nbFollowees;
        uint256 createdAt;
    }

    struct FollowStatus {
        bool isFollowing;
        uint256 followingDate;
    }

    enum ProductType {Digital, Real}
    struct Product {
        ProductType productType;
        address seller;
        uint256 price;
        uint256 quantity;
        bytes32 urlHash;
        bool isActive;
        uint256 createdAt;
    }

    Quadreum private _quadreum;
    uint256 private _lastProductId;
    uint8 private _rewardPercentage;
    uint256 private _minFollowingTimeForReward;
    mapping(address => User) private _users;
    mapping(address => bool) private _admins;
    mapping(address => mapping(address => FollowStatus)) private _followers;
    mapping(uint256 => Product) private _products;
    mapping(address => mapping(uint256 => bool)) private _productOwned;
    mapping(uint256 => mapping(address => bool)) private _productOwners;
    mapping(address => mapping(address => uint256)) private _rewards;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Squarrin: Only administrators can do this");
        _;
    }

    modifier onlyForRegisteredUser(address addr) {
        require(_users[addr].createdAt != 0, "Squarrin: User is not registered");
        _;
    }

    modifier onlyForUnregisteredUser(address addr) {
        require(_users[addr].createdAt == 0, "Squarrin: User is already registered");
        _;
    }

    // TESTED
    modifier onlyValidPercentage(uint8 percentage) {
        require(percentage >= 0 && percentage <= 100, "Squarrin: Invalid percentage number");
        _;
    }

    modifier onlyForActiveSell(uint256 productId) {
        require(_products[productId].isActive, "Squarrin: Sell is not active");
        _;
    }

    // TESTED
    constructor(address admin, uint8 percentage) public onlyValidPercentage(percentage) {
        _minFollowingTimeForReward = 4 weeks;
        _lastProductId = 0;
        _rewardPercentage = percentage; //need a _setPercentage and modifier 0 <= X <= 100
        _admins[admin] = true;
    }

    function followingTimeForReward() public view returns (uint256) {
        return _minFollowingTimeForReward;
    }

    // TESTED
    function lastProductId() public view returns (uint256) {
        return _lastProductId;
    }

    // TESTED
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    // TESTED
    function rewardPercentage() public view returns (uint8) {
        return _rewardPercentage;
    }

    // Todo setRewardPercentage

    // TESTED
    function setQuadreum() external {
        require(address(_quadreum) == address(0), "Squarrin: Quadreum address is already set");
        _quadreum = Quadreum(msg.sender);
    }

    // TESTED
    function getQuadreum() public view returns (address) {
        return address(_quadreum);
    }

    receive() external payable {}

    // TESTED
    function register(address addr, bool isContentCreator)
        public
        onlyAdmin
        onlyForUnregisteredUser(addr)
        returns (bool)
    {
        _users[addr] = User({isContentCreator: isContentCreator, nbFollowers: 0, nbFollowees: 0, createdAt: now});
        return true;
    }

    // TESTED
    function setContentCreator(address addr, bool isContentCreator) public onlyAdmin onlyForRegisteredUser(addr) {
        _users[addr].isContentCreator = isContentCreator;
    }

    // TESTED
    function getUser(address addr) public view onlyForRegisteredUser(addr) returns (User memory) {
        return _users[addr];
    }

    // TESTED
    function follow(address follower, address followee)
        public
        onlyAdmin
        onlyForRegisteredUser(follower)
        onlyForRegisteredUser(followee)
    {
        require(!_followers[follower][followee].isFollowing, "Squarrin: Only follow unfollowed user");
        _users[followee].nbFollowers += 1;
        _users[follower].nbFollowees += 1;
        _followers[follower][followee] = FollowStatus(true, now);
    }

    // TESTED
    function isFollowing(address follower, address followee) public view returns (FollowStatus memory) {
        return _followers[follower][followee];
    }

    // TESTED
    function unfollow(address follower, address followee)
        public
        onlyAdmin
        onlyForRegisteredUser(follower)
        onlyForRegisteredUser(followee)
    {
        require(_followers[follower][followee].isFollowing, "Squarrin: Only unfollow followee");
        _users[followee].nbFollowers -= 1;
        _users[follower].nbFollowees -= 1;
        _followers[follower][followee] = FollowStatus(false, 0);
    }

    /*
        ProductType productType;
        address seller;
        uint256 price;
        uint256 quantity;
        bytes32 urlHash;
        bool isActive;
        uint256 createdAt;
    */
    function sell(
        address seller,
        ProductType productType,
        uint256 price,
        uint256 quantity,
        bool isFinite,
        bytes32 urlHash
    ) public onlyAdmin onlyForRegisteredUser(seller) returns (bool) {
        if (productType == ProductType.Real && !isFinite) {
            revert("Squarrin: Real product must have a finite supply");
        }
        if (!isFinite) {
            quantity = type(uint256).max;
        }
        Product memory product = Product(productType, seller, price, quantity, urlHash, true, now);
        _lastProductId += 1;
        _products[_lastProductId] = product;
        return true;
    }

    function stopSell(uint256 productId) public onlyAdmin onlyForActiveSell(productId) returns (bool) {
        _products[productId].isActive = false;
    }

    function product(uint256 productId) public view returns (Product memory) {
        return _products[productId];
    }

    /*
    function getProduct(uint256 id) public view returns (Product memory) {
        return _products[id];
    }
    */

    //function sell()
    //function stopSell()
    //function deleteProduct()
    //function buy(){
    // apply the reward when a sell is made
    //}
    //function withdrawReward()
    // reward things
}

// TODO
/*
contract Squarrin {



    function getReward(address followee) public view returns (uint256) {
        return token.rewardBy(followee) / users[followee].nbFollowers;
    }

    function withdrawReward(address followee) public returns (bool) {
        // TODO rewardTransferFrom instead of transferFrom
        require(users[msg.sender].followees[followee], "Squarrin: Only followers can get reward");
        token.rewardTransferFrom(followee, msg.sender, token.rewardBy(followee) / users[followee].nbFollowers);
        return true;
    }

    function cashout(uint256 nbTokens) public returns (bool) {
        require(users[msg.sender].isContentCreator, "Squarrin: Only content creator can cashout");
        require(token.balanceOf(msg.sender) >= nbTokens, "Squarrin: Not enough balance for cashout");
        uint256 _etherAmount = 10; //need to calculate ethers WHERE IS PRICE OF TOKEN ?
        token.burn(msg.sender, nbTokens);
        msg.sender.transfer(_etherAmount);
        //exchange nbTokens for Ether or dollars
        return true;
    }


    function buy(uint256 id) public {
        // get price
        // Decrease nb quantity
        // transferFrom
    }

}



import "../GSN/Context.sol";
import "../math/SafeMath.sol";
contract PaymentSplitter is Context {
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    constructor (address[] memory payees, uint256[] memory shares) public payable {
        // solhint-disable-next-line max-line-length
        require(payees.length == shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares[i]);
        }
    }
    receive () external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }


    function totalShares() public view returns (uint256) {
        return _totalShares;
    }


    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }


    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }


    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }


    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
}
*/
