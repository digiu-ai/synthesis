const { timeout } = require("../../utils/utils");
const { ethers, upgrades } = require("hardhat");


async function main() {

    const [deployer] = await ethers.getSigners();
    const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());


    //BRIDGE
    const Bridge = await ethers.getContractFactory("Bridge");
    const bridge = await Bridge.deploy(forwarderRinkeby);// todo add node address
    console.log("Bridge deployed to:", bridge.address);


    // SYNTHESIS
    const Synthesis = await ethers.getContractFactory("Synthesis");
    const synthesis = await upgrades.deployProxy(Synthesis, [bridge.address, forwarderRinkeby]);
    console.log("Synthesis deployed to:", synthesis.address);


    const Portal = await ethers.getContractFactory("Portal");
    const portal = await upgrades.deployProxy(Portal, [bridge.address, forwarderRinkeby]);
    console.log("Portal deployed to:", portal.address);


    // only snt's can transmit requests
    await bridge.updateDexBind(portal.address, true)
    await bridge.updateDexBind(synthesis.address, true)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
