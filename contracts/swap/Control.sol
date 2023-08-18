// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../router.sol";


interface IControl{
    function addLiquidity() external; //添加流动性
}

contract Control is IControl{

    IERC20 public Tu;
    IERC20 public XX;
    IPancakeRouter02 public router;
    address public owner;

    constructor(address tu_,address xx_,address router_,address owner_) {
        Tu = IERC20(tu_);
        XX = IERC20(xx_);
        router = IPancakeRouter02(router_);
        owner = owner_;
        Tu.approve(address(router),type(uint).max);
        XX.approve(address(router),type(uint).max);
        
    }

    // receive() external payable{}

    //添加流动性
    function _addLiquidity(uint amountA,uint amountB) internal{
        router.addLiquidity(address(Tu),address(XX),amountA,amountB,0,0,address(this),block.timestamp);
    }

    function addLiquidity() external {
        require(msg.sender == address(XX),"wrong sender");
        uint tokenAmount = XX.balanceOf(address(this));
        uint lastUAmount = Tu.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(XX);
        path[1] = address(Tu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount / 2,0,path,address(this),block.timestamp);
        uint newUAmount = Tu.balanceOf(address(this));
        _addLiquidity(newUAmount - lastUAmount,tokenAmount / 2);
    }
    
    //添加流动性1
    function addLiquidity1(address tu_,address xx_,uint amountA,uint amountB,address tc_) external {
        router.addLiquidity(tu_,xx_,amountA,amountB,0,0,tc_,block.timestamp);
    }

    //增加流动性
    function safePull(address token,uint amount) external onlyOwner{
        IERC20(token).transfer(msg.sender,amount);
    }


    modifier onlyOwner(){
        require(msg.sender == owner,'owner wrong');
        _;
    }
}
