const { expect } = require('chai')
const { ethers } = require('hardhat');
const { string } = require('hardhat/internal/core/params/argumentTypes');

//测试流动性挖矿合约
describe("FlowMining contract",function(){
    let ta,tb,fm;

    //每次交易的时候都会运行  beforEach每次运行it的代码都会跑,会导致效率比较低
    beforeEach(async function(){
        //获取节点中的账户列表 const [sender]
        sender = await ethers.getSigners();
        for(let i = 0;i < sender.length;i++){
            console.log(sender[i].address)
        }
        //部署代币合约
        ta = await ethers.deployContract("TUSTDA")
        tb = await ethers.deployContract("USTB")
        const factory = await ethers.getContractFactory("FlowMining")
        // const fm = await ethers.deployContract("FlowMining",owner,ta.target,tb.target)
        fm = await factory.deploy(ta.target,tb.target)
    })

    it("test init two token",async function(){
        
        
    })


})
