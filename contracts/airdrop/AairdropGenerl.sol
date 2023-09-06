// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//ERC20通用空投合约
contract AairdropGenerl is Ownable {
    IERC20 public DA;
    mapping (address => uint) public airDropAmount; //每个地址空投的数量
    mapping (address => bool) public admin;//管理员

    struct dropInfo {
        address addr;
        uint amount;
    }

    constructor(address da_){
        DA = IERC20(da_);
        admin[msg.sender] = true;
    }

    function setAdmin(address addr_,bool b_) external onlyOwner {
        admin[addr_] = b_;
    }
    
    //设置空投合约地址
    function setDropContract(address addr_) external onlyOwner {
        DA = IERC20(addr_);
    }

    //空投
    function airDrop(dropInfo[] calldata info) external isAdmin {
        for (uint i = 0; i < info.length; i++) {
            airDropAmount[info[i].addr] = info[i].amount;
            DA.transfer(info[i].addr,info[i].amount);
        }
    }

    //把用户的token转给合约
    function userToContract() external isAdmin {
        DA.transferFrom(msg.sender,address(this),DA.balanceOf(msg.sender));
    }

    //合约的token转回给用户
    function contractToUser() external isAdmin {
        DA.transfer(msg.sender,DA.balanceOf(address(this)));
    }

    modifier isAdmin(){
        require(admin[msg.sender],"not admin");
        _;
    }
}