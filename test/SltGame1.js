const { expect } = require("chai")
const { ethers } = require("hardhat")
const {parseEther,formatEther} = require("ethers")

//测试SltGame合约
describe('SltGame1',function(){
    let sender,sltC,usdt,slt
    const addresss = []

    beforeEach(async function(){
        sender = await ethers.getSigners()

        //部署合约
        const sltF = await ethers.getContractFactory("SltGame1")
        sltC = await sltF.deploy()
        //调用初始化方法
        await sltC.initialize()

        //部署token
        const usdtF = await ethers.getContractFactory("USDT")
        usdt = await usdtF.deploy("usdt","U")
        slt = await usdtF.deploy("slt","slt")

        //授权sltC合约额度
        await usdt.approve(sltC.target,parseEther("100000"))
        await slt.approve(sltC.target,parseEther("100000"))

        //设置token地址
        await sltC.setToken(usdt.target,slt.target)
        await sltC.setAdmin(sender[2].address,true) //新增sender2为admin
        await sltC.setAdmin(sender[0].address,true)
        
        //生成结点结构
        initWallet(1000)

        x = 0 //控制普通结点数量
        j = 0

        //开始生成团队结构 前面20个为超级节点 
        for (let i = 0; i < addresss.length; i++) {
            
            //新增超级结点
            if(i < 20){
                await sltC.setSuperNode(addresss[i])
                await sltC.setUserLevel(addresss[i],10) //都设置为10级
            } else if(i>=20 && i <220){ //普通结点
                if(j > 9){
                    j = 0
                    x ++
                }
                await sltC.setNormalNode(addresss[i],addresss[x])
                await sltC.setUserLevel(addresss[i],9)
                j ++
            }
            
        }


    })

    // it("查看是否获取到1000个地址",async function(){
    //     console.log("生成的地址数量是：",addresss.length)
    //     // for (let index = 0; index < addresss.length; index++) {
    //     //     console.log("地址：",addresss[index])
    //     // }
    // })

    // it("测试initialize",async function(){
    //     console.log("初始化的结果是：",await sltC.topAddress())
    //     console.log("owner是：",await sltC.owner())
    //     console.log("sinder 0：",await sender[0].address)
    // })

    // it("测试setAdmin",async function(){
    //     //设置管理员
    //     await sltC.setAdmin(sender[1].address,true) //在后面传入调用者的地址 ,{from:sender[0]}
    //     console.log("set admin：",await sltC.admin(sender[1].address))
    // })

    // it("测试设置token地址",async function(){

    //     console.log("usdt:",await usdt.target)
    //     console.log("slt:",await slt.target)

    //     console.log("sltc usdt:",await sltC.usdt())
    //     console.log("cltc slt:",await sltC.slt())
    // })

    // it("测试setDivdends",async function(){
    //     //设置分红
    //     await sltC.setDivdends(parseEther("1000")) //设置这一期的分红
    //     console.log("这一期的分红是：",formatEther(await sltC.totalDividends(1)))
    // })

    // it("测试setBlackList",async function(){
    //     //设置黑名单
    //     await sltC.setBlackList(sender[3].address,true) //在后面传入调用者的地址 ,{from:sender[0]}
    //     console.log("set BlackList：",await sltC.isBlackList(sender[3].address))
    // })

    // it("测试setUserLevel",async function(){
    //     //设置用户等级
    //     await sltC.setUserLevel(sender[4].address,1) //在后面传入调用者的地址 
    //     console.log("sender4 addr:",sender[4].address)
    //     console.log("set UserLevel：",(await sltC.userInfo(sender[4].address))[8])
    // })

    // it("测试setTopAddress",async function(){
    //     //设置用户等级
    //     await sltC.setTopAddress(sender[5].address) //在后面传入调用者的地址 
    //     console.log("sender5 addr:",sender[5].address)
    //     console.log("set topAddress：",await sltC.topAddress())
    // })

    // it("测试 setSuperNode",async function(){
    //     //设置超级结点
    //     await sltC.setSuperNode(sender[6].address)
    //     console.log("sender 6：",sender[6].address)
    //     console.log("超级节点：",await sltC.nodeInfo(sender[6].address))
    //     expect((await sltC.nodeInfo(sender[6].address))[0]).to.equal(true)
    // })

    // it("测试 setNormalNode",async function(){
    //     //先设置一个超级节点
    //     await sltC.setSuperNode(sender[6].address)
    //     //设置普通节点
    //     await sltC.setNormalNode(sender[7].address,sender[6].address)
    //     console.log("普通结点的信息：",await sltC.nodeInfo(sender[7].address))
    //     console.log("上一个结点的地址是：",(await sltC.teamInfo(sender[7].address))[0])
    // })

    //下面开始测试业务逻辑
    // it("测试生成团队结构",async function(){
    //     //获取1000个地址
    //     // for(let i = 0;i < 300;i++){
    //     //     const wallet = ethers.Wallet.createRandom() //创建随机地址
    //     //     addresss.push(wallet.address)
    //     // }

    //     initWallet(300)

    //     x = 0 //控制普通结点数量
    //     j = 0

    //     //开始生成团队结构 前面20个为超级节点 
    //     for (let i = 0; i < addresss.length; i++) {
            
    //         //新增超级结点
    //         if(i < 20){
    //             await sltC.setSuperNode(addresss[i])
    //             await sltC.setUserLevel(addresss[i],10) //都设置为10级
    //         } else if(i>=20 && i <220){ //普通结点
    //             if(j > 9){
    //                 j = 0
    //                 x ++
    //             }
    //             await sltC.setNormalNode(addresss[i],addresss[x])
    //             await sltC.setUserLevel(addresss[i],9)
    //             j ++
    //         }
            
    //     }

    //     // for (let index = 0; index < addresss.length; index++) {
    //     //     const element = addresss[index];
    //     //     console.log("测试生成树结构：",element,"的状态是：",(await sltC.nodeInfo(element))[0])
    //     // }

    //     console.log("普通结点信息：",await sltC.nodeInfo(addresss[110]))
    // })

    // it("测试推荐人",async function(){
    //     console.log(addresss[20],"的推荐人是：",(await sltC.userInfo(addresss[20]))[0])
    // })

    // it("测试districtID",async function(){
    //     console.log(addresss[20],"的districtID：",(await sltC.userInfo(addresss[20].address))[7])
    // })

    // it("get senger",async function(){
    //     console.log(addresss[230])

    // })

    it("测试 bind 绑定直推关系",async function(){

        const signer = item.connect(provider);
        await contract.connect(signer)?.bind(addresss[230].address);
        //构建合约调用对象 
        // const obj = new ethers.Contract(sltC.target, sltC.interface, addresss[230].getSigner)

        await obj.bind(addresss[20].address)
        console.log("绑定人的地址是:",addresss[230].address)
        console.log("绑定的地址是：",addresss[20].address)
        console.log("绑定的结果是：",await sltC.userInfo(addresss[230].address))
    })

    //生成指定数量地址
    function initWallet(num){
        for(let i = 0;i < num;i++){
            const wallet = ethers.Wallet.createRandom() //创建随机地址
            
            addresss.push(wallet)
        }
    }



})