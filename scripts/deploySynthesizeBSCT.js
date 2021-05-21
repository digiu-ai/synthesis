const hre = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
    const bridgeAdrBSCT = "0xBE165370D596e5d6a85AD9F1EbaC709Ee0aaf41C"
    const forwarderForSynthesis = "0xeB230bF62267E94e657b5cbE74bdcea78EB3a5AB" // it is real openGSN trustedForwarder


    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Synt = await ethers.getContractFactory("Synthesis");
    const synt = await Synt.deploy(bridgeAdrBSCT, forwarderForSynthesis);
    console.log("Synthesize deployed to:", synt.address);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
