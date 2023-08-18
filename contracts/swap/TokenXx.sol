// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Control.sol";

contract TokenXx is ERC20,Ownable{

    uint public Fee = 3; //手续费
    mapping(address => bool) public pairs; //判断是否建立pairs
    IControl public control;

    constructor()ERC20("TokenXX","xx"){
        _mint(msg.sender,1000000 ether);
    }

    function setPair(address addr_,bool b) external onlyOwner{
        pairs[addr_] = b;
    }

    function setControl(address control_) external onlyOwner{
        control = IControl(control_);
    }

    //收取手续费转账
    function _commissionTransfer(address from,address to,uint amount) internal returns(bool) {
        
        if (pairs[from] || pairs[to]) {
            uint _fee = amount * Fee / 100;
            _transfer(from,address(control),_fee);
            _transfer(from,to,amount - _fee);
        } else{
            if(balanceOf(address(control) )>= 100 ether) //超过100就增加流动性
                control.addLiquidity();
            _transfer(from,to,amount);
        }
        
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _commissionTransfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _commissionTransfer(owner, to, amount);
        return true;
    }
    
    function mint(address addr,uint amount) external onlyOwner{
        _mint(addr,amount);
    }
}