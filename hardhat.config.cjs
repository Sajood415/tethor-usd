require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    // Add your network configurations here
    // Example for Polygon:
    // polygon: {
    //   url: process.env.POLYGON_RPC_URL || "",
    //   accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    // },
    // Example for BSC:
    // bsc: {
    //   url: process.env.BSC_RPC_URL || "",
    //   accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    // },
  },
  etherscan: {
    apiKey: {
      // Add your API keys here
      // polygon: process.env.POLYGONSCAN_API_KEY || "",
      // bsc: process.env.BSCSCAN_API_KEY || "",
    },
  },
};
