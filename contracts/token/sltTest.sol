// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract sltTest {
    mapping(address => uint) public addressToIndex;
    mapping(uint => address) public indexToAddress;
    //    uint lowNum;
    // function bond(address addr) external {
    //     uint index = addressToIndex[addr];

    // }
    struct UserInfo {
        address invitor;
        uint lastLevel;
        uint lowNum;
    }

    mapping(address => UserInfo) public userInfo;

    constructor() {
        addressToIndex[msg.sender] = 0;
        indexToAddress[0] = msg.sender;
        userInfo[msg.sender].invitor = address(this);
        userInfo[msg.sender].lastLevel = 1;
        userInfo[msg.sender].lowNum = 1;
    }

    //输入index编号，返回这个编号下面三个是哪些编号
    function numToLevel(
        uint index_
    ) public pure returns (uint[3] memory lists) {
        uint temp = index_ * 3 + 1;
        lists[0] = temp;
        lists[1] = temp + 1;
        lists[2] = temp + 2;
    }

    //入参 index编号,level是下面第几层，返回这个编号下面第level层的所有数字的范围
    function levelToArray(
        uint index,
        uint level
    ) public pure returns (uint start, uint end) {
        uint temp = index * 3 ** level;
        for (uint i = 0; i < level - 1; i++) {
            temp += 3 ** (level - i - 1);
        }
        temp += 1;
        uint length = 3 ** level;
        start = temp;
        end = start + length - 1;
    }

    //去往上面寻找上一级最新扫的数字，并且继承
    function findLowNum(address addr) public view returns (uint) {
        uint out;
        while (true) {
            if (addr == address(this)) {
                out = 0;
                break;
            }
            if (userInfo[addr].lowNum == 0) {
                addr = userInfo[addr].invitor;
            } else {
                out = userInfo[addr].lowNum;
                break;
            }
        }
        return out;
    }

    //入参 填入invitor地址，返回这个地址下面可以绑定的位置的index
    function findIndex(address addr) internal returns (uint) {
        uint index = addressToIndex[addr];
        uint out = 0;
        uint level = userInfo[addr].lastLevel; //找到这个地址上一次扫的是第几层
        if (level == 0) {
            //如果没有扫过，就默认1
            level = 1;
        }
        uint lowNum = findLowNum(addr); //找到这个地址上一次扫的数字，如果为0就继承他上一级的
        uint start;
        uint end;
        while (true) {
            if (out != 0) {
                break;
            }
            (start, end) = levelToArray(index, level); //找到这个index下面第level层的所有数字的范围
            if (lowNum <= end) {
                //如果上一次扫的数字在这个范围内，就从上一次扫的数字开始往后找
                if (lowNum < start) {
                    lowNum = start; //强制lowNum进入这个范围
                }
                for (uint i = lowNum; i <= end; i++) {
                    if (indexToAddress[i] == address(0)) {
                        //如果位置是空的，就返回这个位置
                        out = i;
                        userInfo[addr].lowNum = i;
                        userInfo[addr].lastLevel = level;
                        break;
                    }
                    continue;
                }
            }
            level += 1;
        }
        return out;
    }

    function _bind(address sender, address invitor) public {
        require(addressToIndex[sender] == 0, "already bond");
        uint index = findIndex(invitor);
        addressToIndex[sender] = index;
        indexToAddress[index] = sender;
        index -= 1;
        userInfo[sender].invitor = indexToAddress[index / 3];
    }

    //绑定邀请者
    function bind(address invitor) external {
        _bind(msg.sender, invitor);
    }
}
