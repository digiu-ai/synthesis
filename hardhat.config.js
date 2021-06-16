require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");


require('dotenv').config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY || "";
const KOVAN_PRIVATE_KEY = process.env.KOVAN_PRIVATE_KEY || "";
const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY || "";
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY || "";
const BSC_PRIVATE_KEY = process.env.BSC_PRIVATE_KEY || "";


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {}
      }
    ]
  },
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${RINKEBY_PRIVATE_KEY}`],
    },
    bsct: {
      url: `https://data-seed-prebsc-2-s3.binance.org:8545`,
      accounts: [`${RINKEBY_PRIVATE_KEY}`],
    },
    hsct: {
      url: `https://http-testnet.hoosmartchain.com`,
      accounts: [`${RINKEBY_PRIVATE_KEY}`],
    },

  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY
    //apiKey: BSCSCAN_API_KEY

  },
  bscscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: BSCSCAN_API_KEY
  }

};

