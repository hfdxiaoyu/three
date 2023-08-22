// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TUSTDA is Ownable, ERC20 {
    constructor() ERC20("TUSTDA", "A") { 
        _mint(msg.sender, 1e18 ether);
    }

    function mint(address addr_,uint amount_) external onlyOwner  returns (bool){
        require(addr_ != address(0),"The address cannot be zero");
        _mint(addr_, amount_);
        return true;
    }
}