import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"
require("dotenv").config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url:
        process.env.GOERLI_URL ||
        "https://eth-goerli.g.alchemy.com/v2/Ug2FP5RUDiu6hSwNofMWt5wNrSzmhiHA",
      accounts: [process.env.PRIVATE_KEY] ? [process.env.PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 80000000000,
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
