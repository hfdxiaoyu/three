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


    function numToLevel(uint index_) public pure returns (uint[3] memory lists){
        uint temp = index_ * 3 + 1;
        lists[0] = temp;
        lists[1] = temp + 1;
        lists[2] = temp + 2;
    }

    function levelToArray(uint index, uint level) public pure returns (uint start, uint end){
        uint temp = index * 3 ** level;
        for (uint i = 0; i < level - 1; i ++) {
            temp += 3 ** (level - i - 1);
        }
        temp += 1;
        uint length = 3 ** level;
        start = temp;
        end = start + length - 1;
    }

    function findLowNum(address addr) public view returns (uint){
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

    function findIndex(address addr) public returns (uint){
        uint index = addressToIndex[addr];
        uint out = 0;
        uint level = userInfo[addr].lastLevel;
        if (level == 0) {
            level = 1;
        }
        uint lowNum = findLowNum(addr);
        uint start;
        uint end;
        while (true) {
            if (out != 0) {
                break;
            }
            (start, end) = levelToArray(index, level);
            if (lowNum <= end) {
                if (lowNum < start) {
                    lowNum = start;
                }
                for (uint i = lowNum; i <= end; i++) {
                    if (indexToAddress[i] == address(0)) {
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

    function bind(address invitor) external {
        _bind(msg.sender, invitor);
    }

}