import {
    frontEndContractsFile,
    frontEndAbiFile,
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
        const accountable = await ethers.getContractFactory("Accountable")
        const contractAddresses = JSON.parse(
            fs.readFileSync(frontEndContractsFile, "utf8")
        )
        if (chainId in contractAddresses) {
            if (
                !contractAddresses[network.config.chainId!]
                    .includes
                    // avatarNftMe.address
                    ()
            ) {
                contractAddresses[network.config.chainId!]
                    .push
                    // avatarNftMe.target
                    ()
            }
        } else {
            // contractAddresses[network.config.chainId!] = [avatarNftMe.target]
        }
        fs.writeFileSync(
            frontEndContractsFile,
            JSON.stringify(contractAddresses)
        )
        fs.writeFileSync(
            frontEndAbiFile,
            JSON.stringify(accountable.interface.fragments)
        )
        console.log("Front end written!")
    }
}
export default updateUI
updateUI.tags = ["all", "frontend"]
