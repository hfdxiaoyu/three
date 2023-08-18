const { expect } = require("chai")
const { ethers } = require("hardhat")
const {parseEther,formatEther} = require("ethers")
const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { int, string } = require("hardhat/internal/core/params/argumentTypes");


describe('swapXx',function(){
    let sender,wbnb,factory1,pairs,router,tu,xx,control,pairs1;

    //每次交易的时候都会运行  beforEach每次运行it的代码都会跑,会导致效率比较低
    beforeEach(async function(){
        sender = await ethers.getSigners(); //获取发送者和接收者
        
        //weth 、 factory
        // const pairfactory = await ethers.getContractFactory("UniswapV2Pair")
        // pairs =  await pairfactory.deploy()

        const WBNB = await ethers.getContractFactory("WBNB")
        wbnb =  await WBNB.deploy()

        const fafactory1 = await ethers.getContractFactory("UniswapV2Factory")
        factory1 = await fafactory1.deploy(sender[0].address) //sender[0]
        
        const routerfactory = await ethers.getContractFactory("UniswapV2Router02")
        router = await routerfactory.deploy(factory1.target,wbnb.target)

        //部署代币合约
        tu = await ethers.deployContract("TUSTDA")
        const xxfactory = await ethers.getContractFactory("TokenXx")
        xx = await xxfactory.deploy()

        const contyrolfactory = await ethers.getContractFactory("Control")
        control = await contyrolfactory.deploy(tu.target,xx.target,router.target,sender[0].address)
        
        // 给 router 合约授权额度
        await tu.approve(router.target,parseEther('1000000000000'))
        await xx.approve(router.target,parseEther('1000000000000'))
        
        //增加流动性 
        await router.addLiquidity(tu.target,xx.target,parseEther("10000"),parseEther("10000"),0,0,sender[0].address,1692413760)
        pairs1 = await factory1.getPair(tu.target,xx.target)
        // console.log('pairs :',await pairs1)
        await xx.setPair(pairs1,true)
        await xx.setControl(control.target)
    })


    it("查看余额和工厂合约的hash",async function(){
        console.log(formatEther(await tu.balanceOf(sender[0])),formatEther(await xx.balanceOf(sender[0])))
        console.log('ether : ',parseEther('10'))
        console.log("factory hash:",await factory1.INIT_CODE_PAIR_HASH())
    })

    it("添加流动性是否扣除3%手续费",async function(){
        console.log(formatEther(await tu.balanceOf(pairs1)),formatEther(await xx.balanceOf(pairs1)))
    })

    it("测试只添加一边的流动性",async function(){
        await router.addLiquidity(tu.target,xx.target,parseEther("1"),parseEther("100"),0,0,sender[0].address,1692413760)
        console.log(formatEther(await tu.balanceOf(pairs1)),formatEther(await xx.balanceOf(pairs1)))
    })

    it("买是否扣除3%手续费",async function(){
        await router.swapExactTokensForTokensSupportingFeeOnTransferTokens(parseEther('100'),0,[tu.target,xx.target],sender[0],1692413760)
        console.log('买入',formatEther(await xx.balanceOf(control.target)))
        console.log(formatEther(await tu.balanceOf(pairs1)),formatEther(await xx.balanceOf(pairs1)))
        // console.log('lp:',formatEther(await pairs.balanceOf(sender[1])))
        
    })

    it("卖出是否扣除3%手续费",async function(){
        await router.swapExactTokensForTokensSupportingFeeOnTransferTokens(parseEther('100'),0,[xx.target,tu.target],sender[0],1692413760)
        console.log('卖出',formatEther(await xx.balanceOf(control.target)))
        console.log(formatEther(await tu.balanceOf(pairs1)),formatEther(await xx.balanceOf(pairs1)))
    })

    it("是否可以自动添加流动性",async function(){

        await xx.transfer(control.target,parseEther('101'))
        console.log('control 余额',formatEther(await xx.balanceOf(control.target)))
        await xx.transfer(sender[2].address,parseEther('1'))
        let lp = await ethers.getContractAt('UniswapV2Pair',pairs1)
        console.log('卖出',formatEther(await xx.balanceOf(control.target)))
        console.log('lp:',await lp.getReserves())
    })

    // it("查询pair合约流动性",async function(){
    //     let lp = await ethers.getContractAt('UniswapV2Pair',pairs)
    //     // console.log('卖出',formatEther(await xx.balanceOf(control.target)))
    //     // console.log(await lp.balanceOf(control.target))
    //     console.log('lp:',formatEther(await lp.balanceOf(control.target)))
    // })

})