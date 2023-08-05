import {
    frontEndContractsFile,
    frontEndAbiFile,
    frontEndExternalContractAddressesFile,
    networkConfig,
} from "../helper-hardhat-config"
import fs from "fs"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const updateUI: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { network, ethers } = hre
    const chainId = "31337"

    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        const accountableFactory = await ethers.getContract(
            "AccountableFactory"
        )
        const contractAddresses = JSON.parse(
            fs.readFileSync(frontEndContractsFile, "utf8")
        )
        if (chainId in contractAddresses) {
            if (
                !contractAddresses[network.config.chainId!].includes(
                    accountableFactory.target
                )
            ) {
                contractAddresses[network.config.chainId!].push(
                    accountableFactory.target
                )
            }
        } else {
            contractAddresses[network.config.chainId!] = [
                accountableFactory.target,
            ]
        }
        fs.writeFileSync(
            frontEndContractsFile,
            JSON.stringify(contractAddresses)
        )
        fs.writeFileSync(
            frontEndAbiFile,
            JSON.stringify(accountableFactory.interface.fragments)
        )

        const externalContracts = JSON.parse(
            fs.readFileSync(frontEndExternalContractAddressesFile, "utf8")
        )
        if (chainId in externalContracts) {
            if (
                !externalContracts[network.config.chainId!].includes(
                    accountableFactory.target
                )
            ) {
                externalContracts[network.config.chainId!].push(
                    accountableFactory.target
                )
            }
        } else {
            externalContracts[network.config.chainId!] = {
                linkToken: networkConfig[network.config.chainId!].linkToken!,
                keeperRegistrar:
                    networkConfig[network.config.chainId!].keeperRegistrar!,
                keeperRegistry:
                    networkConfig[network.config.chainId!].keeperRegistry!,
                cronUpKeepFactory:
                    networkConfig[network.config.chainId!].cronUpKeepFactory!,
            }
        }
        fs.writeFileSync(
            frontEndExternalContractAddressesFile,
            JSON.stringify(externalContracts)
        )
        console.log("Front end written!")
    }
}
export default updateUI
updateUI.tags = ["all", "frontend"]
