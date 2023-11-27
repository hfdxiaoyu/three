const { expect } = require("chai")
// const { ethers } = require("hardhat")
const { ethers,upgrades } = require("hardhat");
const {parseEther,formatEther} = require("ethers")
const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { int, string } = require("hardhat/internal/core/params/argumentTypes");


describe('boxtest',function(){
    let sender,ubox;

    //每次交易的时候都会运行  beforEach每次运行it的代码都会跑,会导致效率比较低
    beforeEach(async function(){
        sender = await ethers.getSigners(); //获取发送者和接收者
        
        //weth 、 factory
        const boxfactory = await ethers.getContractFactory("Box")
        ubox = await upgrades.deployProxy(boxfactory,[sender[0].address],{ initializer: 'store' })
        await ubox.waitForDeployment() //等待合约部署完成
        
        console.log("合约地址：",ubox.target)
        console.log("owner 地址：",sender[0].address)
    })

    it("测试部署",async function(){
        //测试函数调用
        tx = await ubox.store(1);
        await tx.wait()
        console.log("ubox.story(1) is ok!")

        let s = await ubox.retrieve()
        console.log('查出来的值是：',formatEther(s))
        await expect(tx).to.emit(ubox,"ValueChanged").withArgs(1)
    })

    it("测试调用写入数据与查询数据",async function(){
        let s = await ubox.retrieve()
        console.log('查出来的值是：',formatEther(s))
        //写入数据
        tx = await ubox.store(2)
        await tx.wait()
        let u = await ubox.retrieve()
        console.log('查出来的值是：',formatEther(u))

    })

    it("测试合约升级",async function(){
        const boxv2 = await ethers.getContractFactory('BoxV2')
        console.log("upgrade to BoxV2...")
        //升级合约
        const myboxv2 = await upgrades.upgradeProxy(ubox.target,boxv2)
        await myboxv2.waitForDeployment()
        console.log("BoxV2 address :",myboxv2.target)

        tx1 = await ubox.store(2)
        await tx1.wait()

        tx = await myboxv2.increaseValue()
        await tx.wait()
        let a = await ubox.retrieve()
        
        console.log('查出来的值是：',formatEther(a))
    })

})