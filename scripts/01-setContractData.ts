import { ethers, getNamedAccounts, deployments, network } from "hardhat"
// import { AvatarNftMe } from "../typechain-types"
import { developmentChains } from "../helper-hardhat-config"

async function main() {
    const { deployer } = await getNamedAccounts()
    console.log(deployer)
    const chainId: number = network.config.chainId!
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
