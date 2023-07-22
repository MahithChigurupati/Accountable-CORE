import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import {
    developmentChains,
    DECIMALS,
    AGGREGATOR_INITIAL_PRICE,
} from "../helper-hardhat-config"

const deployMocks: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deployments, getNamedAccounts, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    if (developmentChains.includes(network.name)) {
        log("Local network detected! Deploying mocks...")

        await deploy("MockV3Aggregator", {
            contract: "MockV3Aggregator",
            from: deployer,
            log: true,
            args: [DECIMALS, AGGREGATOR_INITIAL_PRICE],
        })

        await deploy("MockWethToken", {
            contract: "MockWethToken",
            from: deployer,
            log: true,
            args: ["Wrapped Ether", "WETH"],
        })

        await deploy("MockWbtcToken", {
            contract: "MockWbtcToken",
            from: deployer,
            log: true,
            args: ["Wrapped Bitcoin", "WBTC"],
        })

        await deploy("MockUsdcToken", {
            contract: "MockUsdcToken",
            from: deployer,
            log: true,
            args: ["USD Coin", "USDC"],
        })

        log("Mocks Deployed!")
        log("----------------------------------")
        log(
            "You are deploying to a local network, you'll need a local network running to interact"
        )
        log(
            "Please run `yarn hardhat console` to interact with the deployed smart contracts!"
        )
        log("----------------------------------")
    }
}

export default deployMocks
deployMocks.tags = ["all", "mocks"]
