const { expect } = require("chai");

describe("Greeter", function() {
  it(" Portal upgrade works", async () => {
    const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
    const bridge = "0x543B7ED5b1eF111B45b23B39E369757587F33987"
    const PortalV1 = await ethers.getContractFactory("Portal");
    const portalV1 = await upgrades.deployProxy(PortalV1, [bridge, forwarderRinkeby]);

    const PortalV2 = await ethers.getContractFactory("Portal");
    const upgradedPortal = await upgrades.upgradeProxy(portalV1.address, PortalV2);
    expect(await upgradedPortal.bridge()).to.equal(bridge);
  });
  it(" Synthesis upgrade works", async () => {
    const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
    const bridge = "0x543B7ED5b1eF111B45b23B39E369757587F33987"
    const SynthesisV1 = await ethers.getContractFactory("Synthesis");
    const synthesisV1 = await upgrades.deployProxy(SynthesisV1, [bridge, forwarderRinkeby]);

    const SynthesisV2 = await ethers.getContractFactory("Synthesis");
    const upgradedPortal = await upgrades.upgradeProxy(synthesisV1.address, SynthesisV2);
    expect(await upgradedPortal.bridge()).to.equal(bridge);
  });
});
