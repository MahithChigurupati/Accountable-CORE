import { ethers, getNamedAccounts, deployments, network } from "hardhat"
// import { AvatarNftMe } from "../typechain-types"
import { developmentChains } from "../helper-hardhat-config"

async function main() {
    const { deployer } = await getNamedAccounts()
    console.log(deployer)
    const chainId: number = network.config.chainId!

    // let avatarNftMe: AvatarNftMe
    // if (developmentChains.includes(network.name)) {
    //     console.log("Deploying AvatarNftMe contract to local network")
    //     await deployments.fixture(["all"])
    // }

    // avatarNftMe = await ethers.getContract("AvatarNftMe", deployer)
    // console.log(`Got contract ANME at ${avatarNftMe.target}`)

    // const tokenCounter = await avatarNftMe.getTokenCounter()
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
