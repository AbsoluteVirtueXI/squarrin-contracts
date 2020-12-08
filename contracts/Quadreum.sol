// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Squarrin.sol";

contract Quadreum is ERC777, Ownable {
    uint256 private constant _TOTAL_SUPPLY = 8 * 10**27;
    string private constant _NAME = "Quadreum";
    string private constant _SYMBOL = "QUAD";

    modifier onlyOneDefaultOperator(address[] memory defaultOperators) {
        require(defaultOperators.length == 1, "Quadreum: Only one default operator is allowed");
        _;
    }

    constructor(address owner_, address[] memory defaultOperators)
        onlyOneDefaultOperator(defaultOperators)
        ERC777(_NAME, _SYMBOL, defaultOperators)
    {
        _onCreate(owner_);
    }

    function _onCreate(address owner_) internal virtual {
        _register();
        transferOwnership(owner_);
        _mint(owner(), _TOTAL_SUPPLY, "", "");
    }

    function _register() private {
        Squarrin squarrin = Squarrin(payable(defaultOperators()[0]));
        squarrin.setQuadreum();
    }
}
