require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades'); //引入可升级插件
const dotenv =  require("dotenv")
const config = dotenv.config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity:{
    compilers : [
      {
        version : "0.8.18",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.8.17",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.8.0",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.6.6",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.6.2",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.6.0",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.5.16",
        settings:{
          optimizer: {
              // enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },{
        version : "0.5.0",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      },
      {
        version : "0.4.18",
        settings:{
          optimizer: {
              enabled: true, // 开启优化器
              runs: 200,
            }
          }
      }
    
  ]},
  networks: { //新增测试网络
    hardhat:{
      //默认的测试网络配置，用于本地开发和测试
    },
    bscTestnet: {
      // Binance Smart Chain Testnet 配置
      url: "https://data-seed-prebsc-2-s1.bnbchain.org:8545", // Binance Smart Chain Testnet RPC 地址
      chainId: 97, // Binance Smart Chain Testnet 的 Chain ID
      accounts: [process.env.bscTestnetprivatekey], // 用于测试网络的私钥列表 
      gasPrice: 10000000000
    },
    bscNet: {
      // Binance Smart Chain net 配置
      url: "https://bsc-dataseed.binance.org/", // Binance Smart Chain RPC 地址
      chainId: 56, // Binance Smart Chain 的 Chain ID
      accounts: [process.env.bscNetprivatekey], // 用于主网的私钥列表 
      gasPrice: 10000000000  //这个gas费太高了
    }
  },
  etherscan: {
    apiKey:{
      bscTestnet : process.env.bscTestnetapikey, 
      bscNet : process.env.bscNetapikey, //主网 apikey 没验证过
      bsc : process.env.bscNetapikey, //主网 apikey 
    }
  }
};
