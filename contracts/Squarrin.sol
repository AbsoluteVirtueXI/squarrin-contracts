// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./Quadreum.sol";

// TODO use library Increment and safemath
contract Squarrin {
    struct User {
        bool isContentCreator;
        uint256 nbFollowers;
        uint256 nbFollowings;
        uint256 createdAt;
    }

    // TODO: REMOVE this, use only boolean instead and don't use followingDate
    // TODO: need to change the test.
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
    uint256 private _lastProductId; // TODO: should be Increment ?
    uint8 private _rewardPercentage;
    uint256 private _minFollowingTimeForReward;
    mapping(address => User) private _users;
    mapping(address => bool) private _admins;
    mapping(address => mapping(address => FollowStatus)) private _followers;
    mapping(uint256 => Product) private _products;
    mapping(address => mapping(uint256 => bool)) private _productOwned;
    mapping(uint256 => mapping(address => bool)) private _productOwners;
    mapping(address => mapping(address => uint256)) private _rewardsDate;
    mapping(address => uint256) private _rewards;

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

    modifier onlyForEnoughProduct(uint256 productId) {
        require(_products[productId].quantity > 0, "Squarrin: Not enough quantity");
        _;
    }

    modifier onlyFollower(address follower, address following) {
        require(_followers[follower][following].isFollowing, "Squarrin: Only follower can do this");
        _;
    }

    modifier onlyMonthFollower(address follower, address following) {
        require(_followers[follower][following].isFollowing, "Squarrin: Only follower can do this");
        require(
            block.timestamp - _followers[follower][following].followingDate >= _minFollowingTimeForReward,
            "Squarrin: Not enough following time"
        );
        _;
    }

    modifier onlyMonthlyReward(address follower, address following) {
        require(_)
    }

    // TESTED
    // TODO: ADD following time for reward as parameter
    constructor(address admin, uint8 percentage) onlyValidPercentage(percentage) {
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
        _users[addr] = User({
            isContentCreator: isContentCreator,
            nbFollowers: 0,
            nbFollowings: 0,
            createdAt: block.timestamp
        });
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
    function follow(address follower, address following)
        public
        onlyAdmin
        onlyForRegisteredUser(follower)
        onlyForRegisteredUser(following)
    {
        require(!_followers[follower][following].isFollowing, "Squarrin: Only follow unfollowed user");
        _users[following].nbFollowers += 1;
        _users[follower].nbFollowings += 1;
        _followers[follower][following] = FollowStatus(true, block.timestamp);
    }

    // TESTED
    function isFollowing(address follower, address following) public view returns (FollowStatus memory) {
        return _followers[follower][following];
    }

    // TESTED
    function unfollow(address follower, address following)
        public
        onlyAdmin
        onlyForRegisteredUser(follower)
        onlyForRegisteredUser(following)
    {
        require(_followers[follower][following].isFollowing, "Squarrin: Only unfollow following");
        _users[following].nbFollowers -= 1;
        _users[follower].nbFollowings -= 1;
        _followers[follower][following] = FollowStatus(false, 0);
    }

    function sell(
        address seller,
        ProductType productType,
        uint256 price,
        uint256 quantity,
        bool isFinite,
        bytes32 urlHash
    ) public onlyAdmin onlyForRegisteredUser(seller) returns (uint256) {
        if (productType == ProductType.Real && !isFinite) {
            revert("Squarrin: Real product must have a finite supply");
        }
        if (!isFinite) {
            quantity = type(uint256).max;
        }
        Product memory product = Product(productType, seller, price, quantity, urlHash, true, block.timestamp);
        _lastProductId += 1;
        _products[_lastProductId] = product;
        return _lastProductId;
    }

    function stopSell(uint256 productId) public onlyAdmin onlyForActiveSell(productId) returns (bool) {
        _products[productId].isActive = false;
        return true;
    }

    function getProduct(uint256 productId) public view returns (Product memory) {
        return _products[productId];
    }

    // mapping(address => mapping(uint256 => bool)) private _productOwned;
    // mapping(uint256 => mapping(address => bool)) private _productOwners;
    function buy(
        address buyer,
        uint256 productId,
        uint256 quantity
    )
        public
        onlyAdmin
        onlyForRegisteredUser(buyer)
        onlyForActiveSell(productId)
        onlyForEnoughProduct(productId)
        returns (bool)
    {
        uint256 price = _products[productId].price * quantity;
        require(_quadreum.balanceOf(buyer) >= price);
        uint256 reward = (price * _rewardPercentage) / 100;
        _rewards[_products[productId].seller] = reward;
        uint256 buyerEarning = price - reward;
        _productOwned[buyer][productId] = true;
        _productOwners[productId][buyer] = true;
        _products[productId].quantity -= 1;
        _quadreum.operatorSend(buyer, _products[productId].seller, buyerEarning, "", ""); // send 95% to buyer
        _quadreum.operatorSend(buyer, address(this), reward, "", ""); // send 5% to smart contract
        return true;
    }

    function withdrawReward(address follower, address following)
        public
        onlyAdmin
        onlyMonthFollower(follower, following)
        returns (bool)
    {
        uint256 rewardAmount = _rewards[following] / _users[following].nbFollowers;
        _rewards[following] -= rewardAmount;
        _quadreum.operatorSend(address(this), follower, rewardAmount, "", "");
        return true;
    }

    // surement faire un _buy() pour generaliser la fonction achat
    // function offerProduct()
    // function tips()
    //function deleteProduct()

    // TODO: store ether in smart contract with a fixed price ??
    function cashOut(address user) public onlyAdmin returns(bool) { 
        return true;
    }

}

// TODO
/*
contract Squarrin {



    function getReward(address following) public view returns (uint256) {
        return token.rewardBy(following) / users[following].nbFollowers;
    }

    function withdrawReward(address following) public returns (bool) {
        // TODO rewardTransferFrom instead of transferFrom
        require(users[msg.sender].followings[following], "Squarrin: Only followers can get reward");
        token.rewardTransferFrom(following, msg.sender, token.rewardBy(following) / users[following].nbFollowers);
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


}
