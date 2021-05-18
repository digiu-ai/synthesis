async function main() {

    const [deployer] = await ethers.getSigners();
    const realALP888 = "0x8aAFC440A5057cF8728c1C23fd74C25314c156ac"

    // set after deploy
    const portalAdr = "0x6F15a295135a4D7A2e9434814333b8fE36EF3BF2"
    const synthesisAdr = "0xEB2715D1defEffBb8696c4E653C4342bAf9cBb3a" // todo set real synthesis

    console.log(
        "Setup contracts with the account:",
        deployer.address
    );
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Synt = await ethers.getContractFactory("Synthesis");
    const synt = await Synt.attach(synthesisAdr);
    console.log("Synthesize attached to ", synt.address)

    await synt.setPortal(portalAdr)

    await synt.createRepresentation(realALP888, "sALP888", "sALP888")

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
