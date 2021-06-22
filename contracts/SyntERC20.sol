// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// Synthesis must be owner of this contract
contract SyntERC20 is  Ownable, ERC20Permit {


    function mint(address account, uint256 amount) onlyOwner external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) onlyOwner external {
        _burn(account, amount);
    }

    constructor (string memory name_, string memory symbol_) ERC20Permit("SymbiosisGSN") ERC20(name_,symbol_)  {}

}
