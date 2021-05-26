const hre = require("hardhat");

async function main() {


    const portal = "0xe82B2332509B7433320408816Bc171F7a4d4bDb7"

    const bridgeAdrRinkeby = "0x819101499057A13f86e401E02296932E09fD0c6d"
    const forwarderForPortal = "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder


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
