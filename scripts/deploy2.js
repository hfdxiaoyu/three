const { ethers,update,network,run } = require("hardhat");
const fs = require("fs")
const {parseEther} = require('ethers/lib/utils')

//这个跑不了
async function main() {
    // 1. 连接到网络
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    

    console.log(contract1.address)
    // 2. 编译合约
    const contractFactory = await ethers.getContractFactory("TUSTD");
    console.log('factory: ',contractFactory)
    const contract = await contractFactory.deploy();
  
    // 3. 等待合约部署完成
    await contract.deployed();
  
    // 4. 打印合约地址
    console.log("Contract address:", contract.address);
  
    // 5. 保存合约地址到文件
    const contractAddress = contract.address;
    fs.writeFileSync("deployedAddress.txt", contractAddress);
  
    // 开源合约
    // try{
    //     await run("verify:verify",{
    //         address: contract.address,
    //     })
    //     console.log("verify contract Successful")
    // } catch(err){

    // }

    // const contract = await ethers.getContractFactory("EnuBNBBET")
    // E = await contract.deploy()
    

  }
  
  // 部署脚本执行入口
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });