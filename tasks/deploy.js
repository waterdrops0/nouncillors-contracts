const { task, ethers, upgrades } = require("hardhat/config");

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
    const ERC2771ForwarderUpgradeable = await hre.ethers.getContractFactory("ERC2771ForwarderUpgradeable");
    const erc2771ForwarderUpgradeable = await ERC2771ForwarderUpgradeable.deploy();
    await erc2771ForwarderUpgradeable.waitForDeployment();
    console.log("Forwarder deployed to:", await erc2771ForwarderUpgradeable.getAddress());

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
    const nouncillorsTokenImplementation = await NouncillorsToken.deploy(erc2771ForwarderUpgradeable.target);
    await nouncillorsTokenImplementation.waitForDeployment();
    console.log("NouncillorsToken deployed to:", await nouncillorsTokenImplementation.getAddress());

    // Initialize NouncillorsToken
    await nouncillorsTokenImplementation.initialize(tokenName, tokenSymbol, nouncillorsDescriptor.target, nouncillorsSeeder.target);
    console.log("NouncillorsToken deployed to:", await nouncillorsTokenImplementation.getAddress(), "and initialized.");

    console.log("Contracts deployed successfully!");
});

module.exports = {};