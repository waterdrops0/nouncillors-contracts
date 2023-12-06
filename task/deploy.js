const { task, ethers } = require("hardhat/config");

task("deploy", "Deploys the Nouncillors contracts")
  .setAction(async () => {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const tokenName = "Nouncillors";
    const tokenSymbol = "NOUNC";

    // Calculate the expected address of NouncillorsArt
    const nonce = await deployer.provider.getTransactionCount(deployer.address); 
    const expectedNouncillorsArtAddress = hre.ethers.getCreateAddress({
      from: deployer.address,
      nonce: nonce + 5
    });
    console.log("The expected Art address is: ", expectedNouncillorsArtAddress);


    // Deploy SVGRenderer
    const SVGRenderer = await hre.ethers.getContractFactory("SVGRenderer");
    const svgRenderer = await SVGRenderer.deploy();
    await svgRenderer.waitForDeployment();
    console.log("SVGRenderer deployed to: ", svgRenderer.target)

    // Deploy Inflator
    const Inflator = await hre.ethers.getContractFactory("Inflator");
    const inflator = await Inflator.deploy();
    await inflator.waitForDeployment();
    console.log("Inflator deployed to:", await inflator.getAddress());

    // Deploy NFTDescriptor
    const NFTDescriptor = await hre.ethers.getContractFactory("NFTDescriptor");
    const nftDescriptor = await NFTDescriptor.deploy();
    await nftDescriptor.waitForDeployment();
    console.log("NFTDescriptor deployed to:", await nftDescriptor.getAddress());
    
    // ERC2771ForwarderUpgradeable
    const ERC2771Forwarder = await hre.ethers.getContractFactory("ERC2771Forwarder");
    const erc2771Forwarder = await ERC2771Forwarder.deploy("NouncilForwarder");
    await erc2771Forwarder.waitForDeployment();
    console.log("Forwarder deployed to:", await erc2771Forwarder.getAddress());

    // Deploy NouncillorsDescriptor with SVGRenderer's address, NFTDescriptor's address, and expected NouncillorsArt address
    const NouncillorsDescriptor = await hre.ethers.getContractFactory("NouncillorsDescriptor", {
      libraries: {
        NFTDescriptor: nftDescriptor.target
      }
    });
    const nouncillorsDescriptor = await NouncillorsDescriptor.deploy(deployer.address, expectedNouncillorsArtAddress, svgRenderer.target);
    await nouncillorsDescriptor.waitForDeployment();
    console.log("NouncillorsDescriptor deployed to:", await nouncillorsDescriptor.getAddress());

    // Deploy NouncillorsArt with NouncillorsDescriptor and Inflator's addresses
    const NouncillorsArt = await hre.ethers.getContractFactory("NouncillorsArt");
    const nouncillorsArt = await NouncillorsArt.deploy(nouncillorsDescriptor.target, inflator.target);
    await nouncillorsArt.waitForDeployment();
    console.log("NouncillorsArt deployed to:", await nouncillorsArt.getAddress());

    // Deploy NouncillorsSeeder
    const NouncillorsSeeder = await hre.ethers.getContractFactory("NouncillorsSeeder");
    const nouncillorsSeeder = await NouncillorsSeeder.deploy();
    await nouncillorsSeeder.waitForDeployment();
    console.log("Seeder deployed to:", await nouncillorsSeeder.getAddress());

     // Deploy the NouncillorsToken implementation contract
    const NouncillorsToken = await hre.ethers.getContractFactory("NouncillorsToken");
    const nouncillorsToken = await NouncillorsToken.deploy(tokenName, tokenSymbol, '0xc0768A60Cf71341C942930E077b7EDf390c3E4c7', erc2771Forwarder.target, nouncillorsSeeder.target, nouncillorsDescriptor.target);
    await nouncillorsToken.waitForDeployment();
    console.log("NouncillorsToken deployed to:", await nouncillorsToken.getAddress());

    console.log("Contracts deployed successfully!");
});

module.exports = {};