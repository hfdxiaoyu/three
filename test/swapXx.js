const { expect } = require("chai")
const { ethers } = require("hardhat")
const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { int, string } = require("hardhat/internal/core/params/argumentTypes");
const { parseEther, formatEther } = require('viem')


//学习loadFixture的使用
describe('swapXx',function(){
    let sender

    //loadFixtureHardhat Network Helpers 中的帮助程序解决了这两个问题。这个助手接收一个固定装置，一个将链设置为某种所需状态的函数。
    async function deploSwapXxFixture(){
        sender = await ethers.getSigners(); //获取发送者和接收者
        
        //weth 、 factory
        const wethfactory = await ethers.getContractFactory("WBNB")
        const weth1 =  await wethfactory.deploy()

        const fafactory1 = await ethers.getContractFactory("CnnFactory")
        const factory1 = await fafactory1.deploy(sender[0])

        const pairfactory = await ethers.getContractFactory("CnnPair")
        const pairs =  await wethfactory.deploy()

        const routerfactory = await ethers.getContractFactory("CnnRouter")
        const router = await routerfactory.deploy(factory1.target,weth1.target)
        
        //部署代币合约
        const tu = await ethers.deployContract("TUSTDA")
        const xxfactory = await ethers.getContractFactory("TokenXx")
        const xx = await xxfactory.deploy()
        
        const contyrolfactory = await ethers.getContractFactory("Control")
        const control = await xxfactory.deploy(tu.target,xx.target,router.target,sender[0])
        
        //给 router 合约授权额度
        await tu.approve(router.target,parseEther('100000000'))
        await xx.approve(router.target,parseEther('100000000'))

        //增加流动性
        await router.addLiquidity(tu.target,xx.target,parseEther("10000"),parseEther("10000"),0,0,sender[0],1691671263)
        pairs = await factory1.getPair(tu.target,xx.target)
        await xx.setPair(pairs,true)
        await xx.setControl(control.target)
        return {tu,pairs,xx}
    }

    it("添加流动性是否扣除3%手续费",async function(){
        const {tu,pairs,xx} = loadFixture(deploSwapXxFixture)
        // console.log(formatEther(await tu.balanceOf(pairs)),formatEther(await xx.balanceOf(pairs)))
        console.log(tu.target)
    })


})