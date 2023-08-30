const { ethers } = require("hardhat");

async function main() {
    let contract;
    const [deployer] = await ethers.getSigners();
    console.log("deployer account:" , deployer.address)
    try {
        const contractFactory = await ethers.getContractFactory("Control")
        contract = await contractFactory.deploy("0xF5D8694cb6C26C2E6549f562366ae807E6F699d3","0x8b3B41D18577b62760056Cb967A1cE874a807E89","0xB3A10a339f1284Bb9AF127c0Ded02a411A2FCce2","0x7A8a96e15fbFEF4C0f4c0F2A4a7296887BeA394A")
        await contract.waitForDeployment()
        console.log('contract address:', contract.target);
        console.log('deployer:', deployer.address);
        // console.log('ACCOUNT BALANCE', await contract.balanceOf(deployer.address));
        console.log('Deployer Successful');
    } catch (error) {
        console.log(error)
    }

    //开源合约  0x79726564A322Eb30884F12F74Bb0AFC953bBFd2f
    try {
      await run("verify:verify",{
        address : contract.target,
        constructorArguments:["0xF5D8694cb6C26C2E6549f562366ae807E6F699d3","0x8b3B41D18577b62760056Cb967A1cE874a807E89","0xB3A10a339f1284Bb9AF127c0Ded02a411A2FCce2","0x7A8a96e15fbFEF4C0f4c0F2A4a7296887BeA394A"], //构造函数,不需要的时候需要注释掉
      })

      console.log("Verify contract successfully")
    } catch (error) {
      console.log("verify error,error is :",error)
    }

  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  