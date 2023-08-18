const { ethers } = require("hardhat");

async function main() {
    //开源合约  0xf8187B6F83790e533DFAB746cAE3B2507c1196Ae
    try {
      await run("verify:verify",{
        address : 0xf8187B6F83790e533DFAB746cAE3B2507c1196Ae,
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
  