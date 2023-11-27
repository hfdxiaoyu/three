const { ethers,upgrades } = require("hardhat");

async function main() {
    let contract,myboxv2;
    const [deployer] = await ethers.getSigners();
    console.log("deployer account:" , deployer.address)
    try {
        // const contractFactory = await ethers.getContractFactory("Box")
        // //部署可升级合约
        // contract = await upgrades.deployProxy(contractFactory,[42],{ initializer: 'store' })
        // await contract.waitForDeployment() //等待合约部署完成

        //合约升级
        const boxv2 = await ethers.getContractFactory('BoxV2')
        console.log("upgrade to BoxV2...")
        //升级合约
        myboxv2 = await upgrades.upgradeProxy("0xD43f27a4a94970e0519c4617f7bF924E27E23027",boxv2)
        await myboxv2.waitForDeployment()
        console.log("BoxV2 address :",myboxv2.target)

        // console.log('contract address:', contract.target);
        // console.log('deployer:', deployer.address);
        // console.log('ACCOUNT BALANCE', await contract.balanceOf(deployer.address));
       
        // console.log("upgrades.erc1967.getImplementationAddress:",await upgrades.erc1967.getImplementationAddress(contract.target))
        // console.log(" getAdminAddress :",await upgrades.erc1967.getAdminAddress(contract.target)) 
        console.log('Deployer Successful');
    } catch (error) {
        console.log(error)
    }

    //开源合约  0x79726564A322Eb30884F12F74Bb0AFC953bBFd2f
    try {
      await run("verify:verify",{
        // address : contract.target,
        address : myboxv2.target
        //constructorArguments:["0x09d7F4ce8A800f3BE56Bb6259aeAdf09BE455034"], //构造函数,不需要的时候需要注释掉
      })

      console.log("Verify contract successfully")
    } catch (error) {
      console.log("verify error,error is :",error)
    }


    //本地部署地址
    // deployer account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    // contract address: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
    // deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  