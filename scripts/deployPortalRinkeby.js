const hre = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
    const bridgeAdrRinkeby = "0x819101499057A13f86e401E02296932E09fD0c6d"
    const forwarderForPortal = "0x956868751Cc565507B3B58E53a6f9f41B56bed74" // it is real openGSN trustedForwarder

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Portal = await ethers.getContractFactory("Portal");
    const portal = await Portal.deploy(bridgeAdrRinkeby, forwarderForPortal);
    console.log("Portal deployed to:", portal.address);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
