const hre = require("hardhat");
//const ethers = require("ethers")

async function main() {

    const [deployer] = await ethers.getSigners();

    // set after deploy
    const portalAdr = "0x6F15a295135a4D7A2e9434814333b8fE36EF3BF2"
    const synthesisAdr = "0xeb2715d1defeffbb8696c4e653c4342baf9cbb3a" // todo set real synthesis

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
