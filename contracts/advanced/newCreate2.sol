// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

//new合约
contract  Car {
    address public owner;
    string public model;
    address public carAddr;

    constructor(address owner_,string memory model_) payable {
        owner = owner_;
        model = model_;
        carAddr = address(this);
    }
}


contract CarFactory{
    Car[] public cars;

    function  create(address _owner,string memory _model) public {
        //(new Car)创建一个新的Car合约实例  
        Car car = (new Car)(_owner,_model); //(_owner,_model) 传递给构造函数的值
        cars.push(car);
    }

    function  createAndSendEther(address _owner,string memory _model) public payable{
        //(new Car)创建一个新的Car合约实例  {value:msg.value} 初始化表达式，用于创建合约时传递eth做为gas费
        Car car = (new Car){value:msg.value}(_owner,_model); //(_owner,_model) 传递给构造函数的值
        cars.push(car);
    }

    function create2(address owner_,string memory model_ ,bytes32 salt_) public {
        Car car = (new Car){salt:salt_}(owner_,model_);
        cars.push(car);
    }

    function create2AndSendEther(
        address _owner,
        string memory _model,
        bytes32 _salt
    ) public payable {
        Car car = (new Car){value: msg.value,salt:_salt}(_owner,_model);
        cars.push(car);
    }

    function getCar(uint _index) public  view  returns (
            address owner,
            string memory model,
            address carAddr,
            uint balance ) {

        Car car = cars[_index];
        return (car.owner(),car.model(),car.carAddr(),address(car).balance);
    }

    //生成salt
    function generateSalt(string memory identifier) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(identifier));
    }


}