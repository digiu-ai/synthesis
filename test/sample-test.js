const { expect, assert } = require("chai");
const { constants, utils, BigNumber } = require("ethers");
const { ethers, network } = require("hardhat");

describe("Upgradable", function() {
  const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
  it(" Portal upgrade works", async () => {
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

describe("Should check snts", function () {
  let portal, synthesis, testToken, sTestToken, sTestTokenAdr
  const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
  let owner, adr1
  const hardhatChainID = 31337


  beforeEach( async () => {
    [owner, adr1] = await ethers.getSigners();

    const bridge = owner.address
    const Portal = await ethers.getContractFactory("Portal");
    portal = await upgrades.deployProxy(Portal, [bridge, forwarderRinkeby]);

    const Synthesis = await ethers.getContractFactory("Synthesis");
    synthesis = await upgrades.deployProxy(Synthesis, [bridge, forwarderRinkeby]);

    const TestToken = await ethers.getContractFactory("SyntERC20");
    testToken = await TestToken.deploy("sTT", "sTTT");

    const mintableAmount = constants.WeiPerEther.mul(90000); // 10%
    await testToken.mint(owner.address, mintableAmount)

    await testToken.approve(portal.address, mintableAmount)


    console.log("Hardhat chain id is",hardhatChainID)

    await synthesis.createRepresentation(testToken.address, hardhatChainID, "sTT", "sTT")

    let syntKey = ethers.utils.solidityKeccak256(["address", "uint"], [testToken.address, hardhatChainID] )
    sTestTokenAdr = await synthesis.representationSynt(syntKey)

    console.log("synt representation is ", sTestTokenAdr)

    const STestToken = await ethers.getContractFactory("SyntERC20");
    sTestToken = await STestToken.attach(sTestTokenAdr);
    console.log("Synthesize attached to ", sTestToken.address)


  });

  it("Should synt some sTT", async () => {
    console.log("supply of sTT for adr1 is %s", await sTestToken.balanceOf(adr1.address))
    const mintableAmount = constants.WeiPerEther.mul(10); // 10%
    let bytes32Id = ethers.utils.formatBytes32String("some id 1234345235")
    let txSynt = await synthesis.mintSyntheticToken(bytes32Id, testToken.address, hardhatChainID, mintableAmount, adr1.address)
    let receipt1 = await txSynt.wait();
    console.log(receipt1)
    let sTokenBallance = await  sTestToken.balanceOf(adr1.address)
    console.log("supply of sTT for adr1 is %s", sTokenBallance)
    expect(sTokenBallance).to.equal( mintableAmount);



  });
});
