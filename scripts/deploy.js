const { ethers } = require("hardhat");

async function deploy(name){
    let contract;
    const [deployer] = await ethers.getSigners();
    console.log("deployer account:" , deployer.address)
    try {
        const contractFactory = await ethers.getContractFactory(name)
        contract = await contractFactory.deploy()
        await contract.waitForDeployment()
        console.log('contract address:', contract.target);
        console.log('deployer:', deployer.address);
        // console.log('ACCOUNT BALANCE', await contract.balanceOf(deployer.address));
        console.log('Deployer Successful');
    } catch (error) {
        console.log(error)
    }
}

async function main(){
    deploy("TUSTDA")
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})