const hre = require("hardhat");

async function main() {

    const synthesis = "0xEb719187e5aacdd3d1b768417842BAcB60ebe895"

    const bridge = "0xBE165370D596e5d6a85AD9F1EbaC709Ee0aaf41C"
    const forwarder = "0x58f24A413F6fb98f217600703C7086EA22B49C47" // it is real openGSN trustedForwarder


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
