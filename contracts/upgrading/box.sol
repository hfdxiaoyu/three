//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//可升级合约
contract Box{
    uint private _value;

    //数据改变事件
    event ValueChanged(uint value);

    function store(uint value_) public {
        _value = value_;
        emit ValueChanged(value_);
    }


    function retrieve() public view returns(uint) {
        return _value;
    }

}

contract BoxV2{
    uint private _value;

    //数据改变事件
    event ValueChanged(uint value);

    function store(uint value_) public {
        _value = value_;
        emit ValueChanged(value_);
    }


    function retrieve() public view returns(uint) {
        return _value;
    }

    function increaseValue() external {
        _value ++;
    }
}