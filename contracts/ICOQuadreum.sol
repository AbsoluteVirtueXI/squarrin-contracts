// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
import "./Quadreum.sol";

contract ICOQuad {
    // Declare a FirstErc20 contract
    Quadreum public token;

    // The price of 1 token in wei;
    uint256 private _price;

    // Address of token seller
    address payable private _seller;

    uint256 private _ratio;

    uint256 private _decimal;

    constructor(
        uint256 price, // price pour 1 CALK
        address payable seller,
        address quadreumAddress
    ) {
        _price = price;
        _seller = seller;
        token = Quadreum(quadreumAddress);
        _decimal = (10**uint256(token.decimals()));
    }

    function getCurrentPrice() public view returns (uint256) {
        return _price;
    }

    function getPricePerNbTokens(uint256 nbTokens) public view returns (uint256) {
        uint256 buyPrice = (nbTokens * _price) / _decimal;
        require(buyPrice > 0, "ICOQuad: Need a higher number of tokens");
        return buyPrice;
    }

    function getNbTokensPerPrice(uint256 _buyPrice) public view returns (uint256) {
        uint256 nbTokens = (_buyPrice * _decimal) / _price;
        require(nbTokens > 0, "ICOQuad: Need a higher amount of ether for buying tokens");
        return nbTokens;
    }

    receive() external payable {
        buy(getNbTokensPerPrice(msg.value));
    }

    // nbTokens en wei de CALK
    function buy(uint256 nbTokens) public payable returns (bool) {
        // check if ether > 0
        require(msg.value > 0, "ICOQuad: purchase price can not be 0");
        // check if nbTokens > 0
        require(nbTokens > 0, "ICOQuad: Can not purchase 0 tokens");
        // check if enough ethers for nbTokens
        require(msg.value >= getPricePerNbTokens(nbTokens), "ICOQuad: Not enough ethers for purchase");
        uint256 _realPrice = getPricePerNbTokens(nbTokens);
        uint256 _remaining = msg.value - _realPrice;
        token.transferFrom(_seller, msg.sender, nbTokens);
        _seller.transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }
}
