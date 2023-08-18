// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SustainIDO is Ownable {

    IERC20 public TU;
    IERC20 public TC;

    constructor(address Tu_,address Tc_){
        TU = IERC20(Tu_);
        TC = IERC20(Tc_);
    }

    uint private price = 1e18; //币价

    struct UserInfo{
        uint getamount; //得到的数量
        uint unum; //购买的usdt
    }
    receive() external payable {}
    mapping(address => UserInfo) public userInfo; //用户购买代币总数 1w + 4w + 15w + 50 w 

    uint[] public tcNum = [100,200,300,500]; //前面四个是ido的轮次对应的数量 000
    uint[] private mutiples = [10,5,2,1]; //存储对应的倍数关系
    address private tuAccount = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; //官方usdt账户
    address private tcAccount = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; //官方c账户

    function setTuAccount(address addr_) external onlyOwner returns(bool){
        tuAccount = addr_;
        return true;
    }

    function setTcAccount(address addr_) external onlyOwner returns(bool){
        tcAccount = addr_;
        return true;
    }

    //购买ido的方法  这里的amount是usdt notZeroAddr(addr_)
    function buy(uint amount_) external payable oneUser returns(bool) {
        require(amount_ > 0,"amount num greater than zero");
        require(tcNum[3] > 0,"ido over");
        address _sender = msg.sender;
        userInfo[_sender].unum += amount_ * price; //先存储买的数量usdt
        
        for (uint i = 0; i < 4; i++) {
            uint _temp = mutiples[i] * userInfo[_sender].unum;

            if (tcNum[i] > 0 && (i == 0 || (i>0 && tcNum[i-1] == 0))){
                if ((tcNum[i] * price) < _temp){ //没有全买到的情况
                    _temp -= tcNum[i] * price;
                    userInfo[_sender].getamount += tcNum[i] * price;
                    userInfo[_sender].unum -= (tcNum[i] * price) / mutiples[i];
                    tcNum[i] = 0;
                    if (userInfo[_sender].unum == 0)
                        break;
                } else {
                    userInfo[_sender].getamount += _temp;
                    userInfo[_sender].unum -= _temp / mutiples[i]; //得到倍数
                    tcNum[i] -= _temp / price;    
                    if (userInfo[_sender].unum == 0)
                        break;
                } 
            } 
            
        }

        TU.transferFrom(_sender,tuAccount, (amount_ * price));

        return true;
    }

    //查询买到的数量
    function getBuyNum(address addr_) public view returns(uint){
        return userInfo[addr_].getamount;
    } 

    //查询usdt余额
    function getTuBalance(address addr_) public view returns(uint){
        return TU.balanceOf(addr_);
    }

    //领取自己买的ustc
    function receiveUSTC() public returns(bool) {
        address _sender = msg.sender;
        require(tcNum[3] == 0,"ido not over");
        require(userInfo[_sender].getamount != 0,"you balance not enough");
        TC.transferFrom(tcAccount,_sender,userInfo[_sender].getamount);
        userInfo[_sender].getamount = 0;
        return true;
    }

    //领取自己的usdt
    function receiveUSTD() public returns(bool){
        address _sender = msg.sender;
        require(tcNum[3] == 0,"ido not over");
        require(userInfo[_sender].unum > 0,"your balance is not enough");
        TU.transferFrom(tuAccount,_sender,userInfo[_sender].unum);
        userInfo[_sender].unum = 0;
        return true;
    }

    //防止使用合约批量买
    modifier oneUser(){
        require(msg.sender == tx.origin,"not");
        _;
    }
}
