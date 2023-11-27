// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract addInfo{
    address public  owner; //超级管理员

    mapping(address=>string) public info; //用户信息

    //构造函数
    constructor(){
        owner = msg.sender;
    }

    //admin设置用户信息
    function setAdminInfo(address addr_,string memory info_) internal {
        info[addr_]=info_;
    }

    //设置info
    function setInfo(string memory info_) external {
        info[msg.sender] = info_;
    }

    function setUserInfo(address addr_,string memory info_) external isAdmin {
        setAdminInfo(addr_, info_);
    }

    modifier isAdmin(){
        require(owner==msg.sender,"not owner");
        _;
    }

}