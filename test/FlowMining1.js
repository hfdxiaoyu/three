const { expect } = require("chai")
const {ethers} = require("hardhat")
const {loadFixture} = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { int, string } = require("hardhat/internal/core/params/argumentTypes");
const { parseEther } = require('viem')



//学习loadFixture的使用
describe('FlowMining',function(){
    let sender

    //loadFixtureHardhat Network Helpers 中的帮助程序解决了这两个问题。这个助手接收一个固定装置，一个将链设置为某种所需状态的函数。
    async function deployFlowMiningFixture(){
        sender = await ethers.getSigners(); //获取发送者和接收者
        
        //部署代币合约
        const ta = await ethers.deployContract("TUSTDA")
        const tb = await ethers.deployContract("USTB")
        const factory = await ethers.getContractFactory("FlowMining")
        // const fm = await ethers.deployContract("FlowMining",owner,ta.target,tb.target)
        const fm = await factory.deploy(ta.target,tb.target)
        //ta 跟 tb 给 fm 合约授权额度 fm.target
        await ta.approve(fm.target,await ta.totalSupply()) //先授权所有额度
        await tb.approve(fm.target,await tb.totalSupply())
        fm.setPaccount(sender[0]) //设置0为收款地址
        ta.transfer(sender[1],100000000000)
        return {ta,tb,fm}
    }

    // it("test ta transfer",async function(){
    //     const {ta,tb,fm} = await loadFixture(deployFlowMiningFixture)
        
    //     // const amountToSend = ethers.utils.parseEther("1") // 1ETH
    //     //转账
    //     amountToSend = 1
    //     await ta.transfer(sender[0].address,amountToSend)
    //     console.log(sender[0].address)
    //     const recipientBanlance = await ta.balanceOf(sender[0].address)
    //     expect(recipientBanlance).to.equal(amountToSend)
    // })

    it("get all address",async function(){
        const {ta,tb,fm} = await loadFixture(deployFlowMiningFixture)
        // console.log(fm.getPaccount())
        await ta.approve(fm.target,await ta.totalSupply()) //授权所有额度
        console.log(await ta.balanceOf(sender[0]))
        console.log(parseEther('1'))
        console.log("授权额度:",await ta.allowance(ta.target,fm.target))
    })

})  

