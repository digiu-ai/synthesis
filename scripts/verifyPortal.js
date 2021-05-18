const hre = require("hardhat");

async function main() {


    const portal = "0xFF7aD1e9A4f2F4BeB7ACaF9720d4239a5857FB6d"

    const bridgeAdrRinkeby = "0x819101499057A13f86e401E02296932E09fD0c6d"
    const forwarderForPortal = "0x956868751Cc565507B3B58E53a6f9f41B56bed74" // it is real openGSN trustedForwarder


    await hre.run("verify:verify", {
        address: portal,
        constructorArguments: [
            bridgeAdrRinkeby,
            forwarderForPortal,
        ],
    })
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
