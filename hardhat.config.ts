import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@nomicfoundation/hardhat-ethers"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import "@nomiclabs/hardhat-solhint"

import dotenv from "dotenv"

dotenv.config()

// RPC URLS
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || ""
const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL || ""
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL || ""
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || ""

// PRIVATE KEYS
const LOCALHOST_PRIVATE_KEY = process.env.LOCALHOST_PRIVATE_KEY || ""
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || ""
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY || ""
//////// MAINNETS /////////
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY || ""
const POLYGON_PRIVATE_KEY = process.env.POLYGON_PRIVATE_KEY || ""

// API KEYS
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || ""

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.20",
            },
            {
                version: "0.6.6",
            },
        ],
        settings: {
            optimizer: {
                enabled: true,
            },
        },
    },

    networks: {
        hardhat: {
            chainId: 1337,
            allowUnlimitedContractSize: true,
        },
        localhost: {
            url: "http://localhost:8545",
            chainId: 31337,
            accounts: [LOCALHOST_PRIVATE_KEY],
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            chainId: 11155111,
            accounts: [SEPOLIA_PRIVATE_KEY],
        },
        mumbai: {
            url: MUMBAI_RPC_URL,
            accounts: [MUMBAI_PRIVATE_KEY],
            chainId: 80001,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: [MAINNET_PRIVATE_KEY],
            chainId: 1,
        },
        polygon: {
            url: POLYGON_RPC_URL,
            accounts: [POLYGON_PRIVATE_KEY],
            chainId: 137,
        },
    },

    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },

    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: COINMARKETCAP_API_KEY,
        // token: "MATIC",
    },

    namedAccounts: {
        deployer: {
            default: 0,
        },
        user: {
            default: 1,
        },
    },
}

export default config
