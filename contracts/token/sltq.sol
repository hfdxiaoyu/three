// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SLTQ is Ownable {
    IERC20 public usdt;
    IERC20 public slt;
    struct UserInfo {
        uint id;
        uint lv; //等级
        uint claimed; 
        uint toClaim;
        uint stakeAmount;
        address inviter; // 邀请者  这三个推荐人相关的先忽略
        address[] referrals; //推荐的人
        address invitor; //推荐人
        uint lastLevel;  //上一级的层级
        uint lowNum; //上一级的位置
    }

    mapping(address => uint) public addressToIndex; //地址映射到索引
    mapping(uint => address) public indexToAddress; //索引映射到地址

    uint public userId = 1;
    mapping(uint => address) public referrer;
    mapping(address => uint) public userIndex;
    mapping(address => UserInfo) public userInfo;
    uint public totalStakeAmount;

    event Stake(address indexed player, uint indexed amount);
    event Unstake(address indexed player, uint indexed amount);

    constructor(address tokenA_, address tokenB_) {
        usdt = IERC20(tokenA_);
        slt = IERC20(tokenB_);
        addressToIndex[msg.sender] = 0;
        indexToAddress[0] = msg.sender;
        userInfo[msg.sender].invitor = address(this);
        userInfo[msg.sender].lastLevel = 1;
        userInfo[msg.sender].lowNum = 1;
    }

    function setToken(address tokenA_, address tokenB_) external onlyOwner {
        usdt = IERC20(tokenA_);
        slt = IERC20(tokenB_);
    }

    function setInviter(address userAddr_) external returns (bool) {
        require(
            userInfo[msg.sender].inviter == address(0),
            "Already have referrals"
        );
        userInfo[msg.sender].inviter = userAddr_;
        userInfo[msg.sender].id = userId;

        if (userInfo[userAddr_].referrals.length < 3) {
            userInfo[userAddr_].referrals.push(msg.sender);
        }

        userId += 1;
        return true;
    }

    function calculateSquareRoot(uint256 index) public pure returns (uint256) {
        require(index >= 1, "Index must be greater than or equal to 1");

        uint256 guess = index / 2;
        uint256 lastGuess;

        while (guess != lastGuess) {
            lastGuess = guess;
            guess = (guess + index / guess) / 2;
        }

        return guess;
    }

    function temp1(uint256 index) public pure returns(uint256) {
        if (index == 1) {
            return 0;
        }

        uint256 lowerBound = 1;
        uint256 upperBound = 2;

        while (true) {
            if (index >= lowerBound * lowerBound && index < upperBound * upperBound) {
                uint256 result = calculateSquareRoot(index);
                return result; // 添加明确的返回语句
            }

            lowerBound = upperBound;
            upperBound *= 2;
        }
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
