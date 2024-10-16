require("@nomicfoundation/hardhat-toolbox");
require("./tasks/deploy");
require('./tasks/populate-descriptor');
require('dotenv').config()

module.exports = {
  solidity: "0.8.22", 
  networks: {
    sepolia: {
      url: process.env.ETH_RPC_URL, 
      accounts: [process.env.PRIVATE_KEY], 
    },
  },
};