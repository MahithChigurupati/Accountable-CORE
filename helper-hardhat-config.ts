import { ethers } from "hardhat"
export interface networkConfigItem {
    name?: string
    weth?: string
    wbtc?: string
    usdc?: string
    ethUsdPriceFeed?: string
    wethUsdPriceFeed?: string
    wbtcUsdPriceFeed?: string
    maticUsdPriceFeed?: string
    usdcUsdPriceFeed?: string
    linkToken?: string
    keeperRegistry?: string
    keeperRegistrar?: string
    cronUpKeepFactory?: string
    blockConfirmations?: number
}

export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    1337: {
        name: "hardhat",
        blockConfirmations: 0,

        //delete later
        linkToken: "0xdd13E55209Fd76AfE204dBda4007C227904f0a81",
        keeperRegistry: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        keeperRegistrar: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        cronUpKeepFactory: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    },
    31337: {
        name: "localhost",
        blockConfirmations: 0,

        //delete later
        linkToken: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        keeperRegistry: "0xdd13E55209Fd76AfE204dBda4007C227904f0a81",
        keeperRegistrar: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        cronUpKeepFactory: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    },
    11155111: {
        name: "sepolia",
        weth: "0xdd13E55209Fd76AfE204dBda4007C227904f0a81",
        wbtc: "0xD0684a311F47AD7fdFf03951d7b91996Be9326E1",
        usdc: "0x6aFb45bfa367ab2E4e55FAA2B1aDAb1bBC5E9A0F",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        wethUsdPriceFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        wbtcUsdPriceFeed: "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43",
        usdcUsdPriceFeed: "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E",

        //change these with real values later
        linkToken: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        keeperRegistry: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        keeperRegistrar: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        cronUpKeepFactory: "0x694AA1769357215DE4FAC081bf1f309aDC325306",

        blockConfirmations: 6,
    },
    80001: {
        name: "mumbai",
        weth: "0x951390f1233f2b48a46f8bc9CB8fa86b395b262C",
        wbtc: "0x0d787a4a1548f673ed375445535a6c7A1EE56180",
        usdc: "0xF493Af87835D243058103006e829c72f3d34b891",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        maticUsdPriceFeed: "0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada",
        wethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        wbtcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        blockConfirmations: 6,
    },
    1: {
        name: "mainnet",
        weth: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        wbtc: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        usdc: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        ethUsdPriceFeed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
        wethUsdPriceFeed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
        wbtcUsdPriceFeed: "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c",
        usdcUsdPriceFeed: "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6",
        blockConfirmations: 6,
    },
    137: {
        name: "polygon",
        weth: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
        wbtc: "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
        usdc: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        maticUsdPriceFeed: "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0",
        wethUsdPriceFeed: "0xF9680D99D6C9589e2a93a78A04A279e509205945",
        wbtcUsdPriceFeed: "0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6",
        usdcUsdPriceFeed: "0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7",
        blockConfirmations: 6,
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const testnetChains = ["mumbai", "sepolia"]

export const frontEndContractsFile =
    "../ACCOUNTABLE-UI/constants/contractAddresses.json"
export const frontEndAbiFile = "../ACCOUNTABLE-UI/constants/abi.json"
export const frontEndExternalContractAddressesFile =
    "../ACCOUNTABLE-UI/constants/externalContractsAddresses.json"

export const DECIMALS = "18"
export const AGGREGATOR_INITIAL_PRICE = ethers.parseEther("2000")

export const INITIAL_MINT_FEE = ethers.parseEther("50")
export const SEND_MINT_FEE = ethers.parseEther("0.1")
export const LOW_MINT_FEE = ethers.parseEther("0.000000000000000001")
export const INCREMENT_THRESHOLD = ethers.parseUnits("50", 0)
export const ONE = ethers.parseUnits("1", 0)
