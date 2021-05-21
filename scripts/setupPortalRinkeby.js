const hre = require("hardhat");
//const ethers = require("ethers")

async function main() {

    const [deployer] = await ethers.getSigners();

    // set after deploy
    const portalAdr = "0xe82B2332509B7433320408816Bc171F7a4d4bDb7"
    const synthesisAdr = "0x1ED347EDd5560c90fc079719B294e3034F39fB76" // todo set real synthesis

    console.log(
        "Setup contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Portal = await ethers.getContractFactory("Portal");
    const portal = await Portal.attach(portalAdr);
    console.log("Portal attached to ", portal.address)

    // only to force hex sting error
    const Synt = await ethers.getContractFactory("Synthesis");
    const synt = await Synt.attach(synthesisAdr);
    console.log("Synthesize attached to ", synt.address)

    await portal.connect(deployer).setSynthesis(synthesisAdr)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
