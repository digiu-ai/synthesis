async function main() {

    const [deployer] = await ethers.getSigners();
    const realALP888 = "0x8aAFC440A5057cF8728c1C23fd74C25314c156ac"

    const synthesisAdr = "0xAa947f1e24344B7F110AdA90D2E053e044454274" // todo set real synthesis

    console.log(
        "Setup contracts with the account:",
        deployer.address
    );
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Synt = await ethers.getContractFactory("Synthesis");
    const synt = await Synt.attach(synthesisAdr);
    console.log("Synthesize attached to ", synt.address)

    await synt.createRepresentation(realALP888, 4, "sALP888", "sALP888")

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
