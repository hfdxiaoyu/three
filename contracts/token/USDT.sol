// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is Ownable, ERC20 {
    constructor(string memory name_,string memory symble_) ERC20(name_, symble_) { 
        _mint(msg.sender, 1e18 ether);
    }

    // function decimals() public view override returns (uint8) {
    //     return 6;
    // }

    function mint(address addr_,uint amount_) external onlyOwner  returns (bool){
        require(addr_ != address(0),"The address cannot be zero");
        _mint(addr_, amount_);
        return true;
    }
}