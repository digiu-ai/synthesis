const hre = require("hardhat");
const { timeout } = require("../../utils/utils");


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
    const bridge = await Bridge.deploy(forwarderRinkeby);
    console.log("Bridge deployed to:", bridge.address);


    // SYNTHESIS
    const Synthesis = await ethers.getContractFactory("Portal");
    const synthesis = await Synthesis.deploy(bridge.address, forwarderRinkeby);
    console.log("Synthesis deployed to:", synthesis.address);


    const Portal = await ethers.getContractFactory("Portal");
    const portal = await Portal.deploy(bridge.address, forwarderRinkeby);
    console.log("Portal deployed to:", portal.address);


    // only snt's can transmit requests
    await bridge.updateDexBind(portal.address, true)
    await bridge.updateDexBind(synthesis.address, true)

    await timeout(100000);
    await hre.run("verify:verify", {
        address: bridge.address,
        constructorArguments: [
            forwarderRinkeby,
        ],
    })

    await hre.run("verify:verify", {
        address: portal.address,
        constructorArguments: [
            bridge.address,
            forwarderRinkeby,
        ],
    })
    await hre.run("verify:verify", {
        address: synthesis.address,
        constructorArguments: [
            bridge.address,
            forwarderRinkeby,
        ],
    })

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
