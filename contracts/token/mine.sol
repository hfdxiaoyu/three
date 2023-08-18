// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mine is Ownable{
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint public dailyOut = 100000 ether;
    uint public rates = dailyOut / 86400; //每秒产量
    uint public acc = 1e18;
    struct UserInfo{
        uint stakeAmount;
        uint debt;
        uint claimed;
        uint toClaim;
    }
    struct Debt{
        uint debt;
        uint lastTime;
    }
    mapping(address => UserInfo) public userInfo;
    uint public totalStakeAmount;
    Debt public debt;
    event Stake(address indexed player,uint indexed amount);
    event Unstake(address indexed player,uint indexed amount);


    function setToken(address tokenA_,address tokenB_) external onlyOwner{
        tokenA = IERC20(tokenA_);
        tokenB = IERC20(tokenB_);
    }

    //计算dept
    function countingDebt() public view returns(uint _debt){
        if(debt.lastTime == 0){
            return 0;
        }
        if (totalStakeAmount==0){
            return debt.debt;
        }
        _debt = debt.debt;
        _debt += rates * acc / totalStakeAmount * (block.timestamp - debt.lastTime);
        
    }

    //计算奖励
    function _calculateReward(address addr) public view returns(uint){
        uint _tempDiff= countingDebt() - userInfo[addr].debt;
        uint _rew = _tempDiff * userInfo[addr].stakeAmount / acc;
        return _rew;
    }

    function calculateReward(address addr) public view returns(uint){
        return(userInfo[addr].toClaim + _calculateReward(addr));
    }

    function stake(uint amount) external{
        require(amount != 0,'wrong amount');
        uint _tempDebt = countingDebt();
        if(userInfo[msg.sender].stakeAmount > 0){
            userInfo[msg.sender].toClaim += _calculateReward(msg.sender);
        }

        debt.debt = _tempDebt;
        debt.lastTime = block.timestamp;
        totalStakeAmount += amount;
        userInfo[msg.sender].stakeAmount += amount;
        userInfo[msg.sender].debt = _tempDebt;
    }

}



// stake num 
// 1000 ether

// 质押A代币，产出B代币
// 每天产出B代币1000 Ether
// 现在有1000个用户，质押了1000个A代币。每个用户质押了1个A代币
// 每个用户每天可以得到1个B代币的产出

// 一个用户999个A代币，一个用户质押了1个A代币

// 因为每天都会有人质押x的代币进去，也会有人取出y的代币出来

// 假如现在999个A代币，一个用户1个A代币，这个时候我质押100个A代币，隔了一个小时取出来，我能拿到多少个代币，在我质押半个小时后，又有一个人质押了100个进来，我还是一样的时间取出，我能拿到多少

// 1000 /day 
// s = 1000 / 86400

// S = s / 1000.   每个A代币的每秒产出的代币数量


// debt = 0
// startTime = 0

// 第一个人质押
// 999
// startTime  = now
// debt = 0

// S = s / 999 每个A代币每秒产出的数量
// 第二个人质押，隔了10秒钟:

// 1
// lastTime = 10s
// debt += S * 10s 10 秒钟，每个代币可以产出多少个代币
// user.debt = debt
// S = s / 1000
// lastTime = now

// 20S后
// 我
// 100
// debt += S * 20
// user.debt = debt
// S= s/1100
// lastTime = now


// 第二位
// 100 
// debt += S * (now - lastTime)
// user.debt = debt
// S = s/1200
// lastTime = now


// debt += S* (now - lastTime)
// rew = (debt - user.debt) * 100



// 【TVL:999,time:10s, TVL 1000,time:10s】


// 质押代币A，产出代币B，两个代币分别都是18位精度
// 每天B代币产量为10W
// 随存随取