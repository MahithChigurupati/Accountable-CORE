import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import verify from "../utils/verify"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployAccountableFactory: DeployFunction = async function (
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
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].wethUsdPriceFeed!
        btcUsdPriceFeedAddress = networkConfig[chainId].wbtcUsdPriceFeed!
        usdcUsdPriceFeedAddress = networkConfig[chainId].usdcUsdPriceFeed!

        wethTokenAddress = networkConfig[chainId].weth!
        wbtcTokenAddress = networkConfig[chainId].wbtc!
        usdcTokenAddress = networkConfig[chainId].usdc!
    }

    log("----------------------------------------------------")
    log("Deploying Accountable Factory and waiting for confirmations...")

    const tokens = [wethTokenAddress, wbtcTokenAddress, usdcTokenAddress]
    const priceFeeds = [
        ethUsdPriceFeedAddress,
        btcUsdPriceFeedAddress,
        usdcUsdPriceFeedAddress,
    ]

    const args = [tokens, priceFeeds, wethTokenAddress]

    const accountableFactory = await deploy("AccountableFactory", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: networkConfig[chainId].blockConfirmations || 0,
    })

    log(`accountableFactory deployed at ${accountableFactory.address}`)

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(accountableFactory.address, args)
    }
}
export default deployAccountableFactory
deployAccountableFactory.tags = ["all", "accountableFactory"]
