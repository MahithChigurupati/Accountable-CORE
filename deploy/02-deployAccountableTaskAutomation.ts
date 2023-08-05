import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import verify from "../utils/verify"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployAccountableTaskAutomation: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId: number = network.config.chainId!

    let ethUsdPriceFeedAddress: string
    let btcUsdPriceFeedAddress: string
    let usdcUsdPriceFeedAddress: string
    let wethTokenAddress: string
    let wbtcTokenAddress: string
    let usdcTokenAddress: string
    let cronUpKeepFactory: string
    let keeperRegistry: string
    let keeperRegistrar: string
    let linkTokenAddress: string

    if (chainId == 31337 || chainId == 1337) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address

        const btcUsdAggregator = await deployments.get("MockV3Aggregator")
        btcUsdPriceFeedAddress = btcUsdAggregator.address

        const usdcUsdAggregator = await deployments.get("MockV3Aggregator")
        usdcUsdPriceFeedAddress = usdcUsdAggregator.address

        const weth = await deployments.get("MockWethToken")
        wethTokenAddress = weth.address

        const wbtc = await deployments.get("MockWbtcToken")
        wbtcTokenAddress = wbtc.address

        const usdc = await deployments.get("MockUsdcToken")
        usdcTokenAddress = usdc.address

        const link = await deployments.get("MockLinkToken")
        linkTokenAddress = link.address

        keeperRegistry = networkConfig[chainId].keeperRegistry!
        keeperRegistrar = networkConfig[chainId].keeperRegistrar!
        cronUpKeepFactory = networkConfig[chainId].cronUpKeepFactory!
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].wethUsdPriceFeed!
        btcUsdPriceFeedAddress = networkConfig[chainId].wbtcUsdPriceFeed!
        usdcUsdPriceFeedAddress = networkConfig[chainId].usdcUsdPriceFeed!

        wethTokenAddress = networkConfig[chainId].weth!
        wbtcTokenAddress = networkConfig[chainId].wbtc!
        usdcTokenAddress = networkConfig[chainId].usdc!

        keeperRegistry = networkConfig[chainId].keeperRegistry!
        keeperRegistrar = networkConfig[chainId].keeperRegistrar!
        linkTokenAddress = networkConfig[chainId].linkToken!
        cronUpKeepFactory = networkConfig[chainId].cronUpKeepFactory!
    }

    log("----------------------------------------------------")
    log(
        "Deploying Accountable Task Automation and waiting for confirmations..."
    )

    const args = [
        cronUpKeepFactory,
        keeperRegistry,
        keeperRegistrar,
        linkTokenAddress,
    ]

    const accountableTaskAutomation = await deploy(
        "AccountableTaskAutomation",
        {
            from: deployer,
            args: args,
            log: true,
            waitConfirmations: networkConfig[chainId].blockConfirmations || 0,
        }
    )

    log(
        `accountableTaskAutomation deployed at ${accountableTaskAutomation.address}`
    )

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(accountableTaskAutomation.address, args)
    }
}
export default deployAccountableTaskAutomation
deployAccountableTaskAutomation.tags = ["all", "accountableTaskAutomation"]
