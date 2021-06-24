const { timeout } = require("../../utils/utils");
const { ethers, upgrades } = require("hardhat");


async function main() {

    const [deployer] = await ethers.getSigners();
    const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
    const bridgeAdr = "0x44877eafBAEA8561D9C152a3DaE0d5EEA92Ec23a"

    const realToken = "0x8aAFC440A5057cF8728c1C23fd74C25314c156ac"

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Bridge = await ethers.getContractFactory("Bridge");
    const bridge = await Bridge.attach(bridgeAdr);
    console.log("Bridge attached to ", bridge.address)


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

    await synthesis.createRepresentation(realToken, 4, "sALP888", "sALP888")


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
