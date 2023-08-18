const { ethers } = require("hardhat");

async function main() {
    let contract;
    const [deployer] = await ethers.getSigners();
    console.log("deployer account:" , deployer.address)
    try {
        const contractFactory = await ethers.getContractFactory("FlowMining")
        contract = await contractFactory.deploy()
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
  