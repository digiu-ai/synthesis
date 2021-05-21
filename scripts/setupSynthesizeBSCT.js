async function main() {

    const [deployer] = await ethers.getSigners();
    const realALP888 = "0x8aAFC440A5057cF8728c1C23fd74C25314c156ac"

    // set after deploy
    const portalAdr = "0xe82B2332509B7433320408816Bc171F7a4d4bDb7"
    const synthesisAdr = "0x1ED347EDd5560c90fc079719B294e3034F39fB76" // todo set real synthesis

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
