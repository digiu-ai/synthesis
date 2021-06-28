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
  let portal, synthesis, testToken, sTestToken, sTestTokenAdr, portalWithBridge ,bridge, synthesisWithBridge, sTestTokenBridging
  const forwarderRinkeby= "0x83A54884bE4657706785D7309cf46B58FE5f6e8a" // it is real openGSN trustedForwarder
  let owner, adr1
  const hardhatChainID = 31337


  beforeEach( async () => {
    [owner, adr1] = await ethers.getSigners();

    const bridgeAdr = owner.address
    const Portal = await ethers.getContractFactory("Portal");
    portal = await upgrades.deployProxy(Portal, [bridgeAdr, forwarderRinkeby]);

    const Synthesis = await ethers.getContractFactory("Synthesis");
    synthesis = await upgrades.deployProxy(Synthesis, [bridgeAdr, forwarderRinkeby]);

    const TestToken = await ethers.getContractFactory("SyntERC20");
    testToken = await TestToken.deploy("sTT", "sTTT");

    const mintableAmount = constants.WeiPerEther.mul(90000); // 10%
    await testToken.mint(owner.address, mintableAmount)

    await testToken.approve(portal.address, mintableAmount)

    //const hardhatChainID = portal.getChainId()
    console.log("Real Hardhat chain id is", utils.formatUnits(await portal.getChainId(),0))


    await synthesis.createRepresentation(testToken.address, hardhatChainID, "sTT", "sTT")

    let syntKey = ethers.utils.solidityKeccak256(["address", "uint"], [testToken.address, hardhatChainID] )
    sTestTokenAdr = await synthesis.representationSynt(syntKey)

    console.log("synt representation is ", sTestTokenAdr)

    const STestToken = await ethers.getContractFactory("SyntERC20");
    sTestToken = await STestToken.attach(sTestTokenAdr);
    console.log("sTestToken attached to ", sTestToken.address)



    const ListNodeMock = await ethers.getContractFactory("NodeListMock");
    const listNode = await ListNodeMock.deploy();
    console.log("ListNodeMock deployed to:", listNode.address);


    const Bridge = await ethers.getContractFactory("Bridge");
     bridge = await Bridge.deploy(listNode.address);
    console.log("Bridge deployed to:", bridge.address);

    portalWithBridge = await upgrades.deployProxy(Portal, [bridge.address, forwarderRinkeby]);
    synthesisWithBridge = await upgrades.deployProxy(Synthesis, [bridge.address, forwarderRinkeby]);
    await synthesisWithBridge.createRepresentation(testToken.address, hardhatChainID, "sTT", "sTT")

    let syntKey2 = ethers.utils.solidityKeccak256(["address", "uint"], [testToken.address, hardhatChainID] )
    sTestTokenAdr = await synthesisWithBridge.representationSynt(syntKey2)
    sTestTokenBridging =  await STestToken.attach(sTestTokenAdr);
    console.log("sTestTokenBridging attached to ", sTestToken.address)


    await bridge.updateDexBind(portalWithBridge.address, true)
    await bridge.updateDexBind(synthesisWithBridge.address, true)

    await testToken.approve(portalWithBridge.address, mintableAmount)
  });

  it("Should synt some sTT", async () => {
    console.log("supply of sTT for adr1 is %s", await sTestToken.balanceOf(adr1.address))
    const mintableAmount = constants.WeiPerEther.mul(10);
    let bytes32Id = ethers.utils.formatBytes32String("some id 1234345235")
    let txSynt = await synthesis.mintSyntheticToken(bytes32Id, testToken.address, hardhatChainID, mintableAmount, adr1.address)
    let receipt1 = await txSynt.wait();
    //console.log(receipt1)
    let sTokenBalance = await  sTestToken.balanceOf(adr1.address)
    console.log("supply of sTT for adr1 is %s", sTokenBalance)
    expect(sTokenBalance).to.equal(mintableAmount);
  });

  it("Should sent portal req", async () => {



    let oldBalance = await testToken.balanceOf(owner.address)
    const syntAmount = constants.WeiPerEther.mul(10);
    let txSynt = await portalWithBridge.synthesize(testToken.address,syntAmount, adr1.address, synthesisWithBridge.address, bridge.address, hardhatChainID)
    let receipt1 = await txSynt.wait();
    console.log(receipt1)
    let oracleRequest = receipt1.events.filter((x) => {
      return x.event == "OracleRequest";
    });

    let reqID = oracleRequest[0].args[2];
    let selector = oracleRequest[0].args[3];
    let bytesSelector = ethers.utils.arrayify(selector);
    let receiveSide = oracleRequest[0].args[4];
    console.log("Oracle request: ", reqID, selector,receiveSide )
    console.log("is bytes ", ethers.utils.isBytes(bytesSelector))
    await bridge.receiveRequestV2(reqID, bytesSelector, synthesisWithBridge.address, bridge.address)

    expect(oldBalance.sub(syntAmount)).to.equal(await testToken.balanceOf(owner.address));
    expect(syntAmount).to.equal(await sTestTokenBridging.balanceOf(adr1.address));
  });
});
