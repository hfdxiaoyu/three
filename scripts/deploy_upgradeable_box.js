// 部署可升级合约脚本

const {ethers,upgrades} = require('hardhat')
const {deployProxy} = require('@openzeppelin/hardhat-upgrades')

async function main(){
    //得到部署账号
    const {owner} = await ethers.getSigners();
    
    const Box = await ethers.getContractFactory('Box')
    console.log('Deploying Box ...')
    // 将部署账号作为初始化参数传入（因为函数名是initialize，所以opts参数可以省略）
    const box = Box.deployProxy(Box,[42],{initializer:'initializer'})
    // const box = await deployProxy(Box,[42],{initializer:'initializer'})
    // await box.deployed()
    console.log('box delopyed to:',box.address)

    //测试调用函数
    tx = await box.story(1)
    await tx.wait();
    console.log("box,store is ok!")
}

main();