const hre = require("hardhat");

async function main() {

    const synthesis = "0x1ED347EDd5560c90fc079719B294e3034F39fB76"

    const bridge = "0xBE165370D596e5d6a85AD9F1EbaC709Ee0aaf41C"
    const forwarder = "0xeB230bF62267E94e657b5cbE74bdcea78EB3a5AB" // it is real openGSN trustedForwarder


    await hre.run("verify:verify", {
        address: synthesis,
        constructorArguments: [
            bridge,
            forwarder,
        ],
    })
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
