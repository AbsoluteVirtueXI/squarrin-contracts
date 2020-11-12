// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "./Squarrin.sol";

contract Quadreum is ERC777 {
    uint256 private constant _TOTAL_SUPPLY = 8 * 10**27;
    string private constant _NAME = "Quadreum";
    string private constant _SYMBOL = "QUAD";
    address private _owner;
    Squarrin private _squarrin;

    constructor(address owner, address[] memory defaultOperators) public ERC777(_NAME, _SYMBOL, defaultOperators) {
        _owner = owner;
        // defaultOperators[0] is the Squarrin contract address
        _squarrin = Squarrin(payable(defaultOperators[0]));
        _onCreate();
    }

    function _onCreate() internal virtual {
        _mint(_owner, _TOTAL_SUPPLY, "", "");
        _squarrin.setQuadreum();
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getSquarrin() public view returns (address) {
        return address(_squarrin);
    }
}
