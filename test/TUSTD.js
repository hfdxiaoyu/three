const { expect } = require('chai')
const { ethers } = require('hardhat')

//测试合约
describe("Token contract",function(){
    it("Deployment should assign the total supply of tokens to the owner",async function(){
        //获取了我们连接到的节点中的帐户列表
        const [owner] = await ethers.getSigners();
        //部署我们的代币合约
        const hardhatToken = ethers.deployContract("TUSTD")
        
        const ownerBalance = await hardhatToken.balanceOf(owner.address)
        expect(await hardhatToken.totalSupply()).to.equal(ownerBalance)
    })
})
