// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//流动性挖矿
contract FlowMining is Ownable{
    
    IERC20 public TA;
    IERC20 public TB;

    constructor(address ta_,address tb_){
        TA = IERC20(ta_);
        TB = IERC20(tb_);
    }

    uint public acc = 1e18; //精度 
    uint public yeild = 1000 ether; //一天总产量00 
    uint public secyeild = yeild / 86400; //每秒产量
    uint public totalAmount = 0; //a代币的质押总量

    struct UserInfo {
        uint pledgedAmount; //质押总量
        uint debt; //用户开始质押时候的dept
        uint claimed; //之前得到的收益
        uint toClaim; //累计收益
    }

    mapping (address => UserInfo) public userInfo;

    struct Debt{
        uint debt;
        uint lastTime; 
    }

    Debt public debt;
    address public paccount = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; //质押A币的地址

    event Stact(address indexed user,uint indexed amount);
    event UnStact(address indexed user,uint indexed amount);

    //计算dept
    function _calculateDept() internal view returns (uint) {
        if(debt.lastTime == 0){
            return 0;
        }

        if(totalAmount == 0){
            return debt.debt;
        }
        uint _tempdept = debt.debt;
        _tempdept +=  secyeild * acc / totalAmount * (block.timestamp - debt.lastTime);
        return _tempdept;
    }

    //质押挖矿的方法 质押的数量
    function pledge(uint amount_) external {
        address _sender = msg.sender; 
        uint _tempdebt = _calculateDept();
        TA.transferFrom(_sender, paccount, amount_);
        if(userInfo[_sender].pledgedAmount > 0){ //如果之前有质押先领取一次
            userInfo[_sender].claimed += (_tempdebt - userInfo[_sender].debt) * userInfo[_sender].pledgedAmount;
        }
        totalAmount += amount_;
        debt.debt += _tempdebt;
        userInfo[_sender].debt = _tempdebt;
        userInfo[_sender].pledgedAmount += amount_;
        debt.lastTime = block.timestamp;
        emit Stact(_sender,amount_);
    }


    //取消质押挖矿的方法
    function unPledge(uint amount_) external {
        address _sender = msg.sender;
        uint _tempdebt = _calculateDept();
        require(userInfo[_sender].pledgedAmount <= amount_,"Pledge balance is not enough");
        TA.transferFrom(paccount,_sender,amount_);
        //计算收益
        userInfo[_sender].toClaim += (((_tempdebt - userInfo[_sender].debt) * userInfo[_sender].pledgedAmount) + userInfo[_sender].claimed) / acc;
        userInfo[_sender].claimed = 0;
        userInfo[_sender].pledgedAmount -= amount_;
        totalAmount -= amount_;
        //修改debt
        uint _tempdept2 = _calculateDept();
        debt.debt += _tempdept2;
        userInfo[_sender].debt = _tempdept2;
        debt.lastTime = block.timestamp;
        //领取收益
        TB.transferFrom(paccount,_sender,userInfo[_sender].toClaim);
        userInfo[_sender].toClaim = 0;
        emit UnStact(_sender,amount_);
    }

    function setPaccount(address addr_) external onlyOwner returns(bool) {
        paccount = addr_;
        return true;
    }

    function _getClaim(address addr_) internal view returns(uint){
        address _sender = addr_;
        uint _tempdebt = _calculateDept();
        return (((_tempdebt - userInfo[_sender].debt) * userInfo[_sender].pledgedAmount) + userInfo[_sender].claimed) / acc;
    }

    //查询质押奖励
    function getClaim(address addr_) public view  returns(uint){
        return _getClaim(addr_);
    }
}