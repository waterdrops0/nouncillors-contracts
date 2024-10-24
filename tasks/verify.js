async function main() {
  // Contract addresses from the deployment
  const svgRendererAddress = "0x1F32165dAF6De8Cc28a056376fE0d3C6D56A692b";
  const inflatorAddress = "0x98B340eb812D28b1200c19FD6c9401e12E9C8437";
  const nftDescriptorAddress = "0x74aFa86158289407A328C79918cd99b38A219250";
  const erc2771ForwarderAddress = "0xCC22d64456D50Da8E06BC60E5C07D73a1AD5B344";
  const nouncillorsDescriptorAddress = "0x5170738fDd382b4Bf663E62014e5156C627b208a";
  const nouncillorsArtAddress = "0xA699bbD00C232607f8ff04105603f40282F47fA5";
  const nouncillorsTokenAddress = "0x8D047492Adfbb94C6cD48300b5df5e7872Ad0C40";
  const initialOwner = "0xbE41e1Dd8C970AC40E8aB284CDd581e3b35Da51C"; // Initial owner
  
  try {
    // Verify SVGRenderer
    await hre.run("verify:verify", {
      address: svgRendererAddress,
    });

    // Verify Inflator
    await hre.run("verify:verify", {
      address: inflatorAddress,
    });

    // Verify NFTDescriptor
    await hre.run("verify:verify", {
      address: nftDescriptorAddress,
    });

    // Verify ERC2771Forwarder
    await hre.run("verify:verify", {
      address: erc2771ForwarderAddress,
      constructorArguments: ["NouncilForwarder"]
    });

    // Verify NouncillorsDescriptor
    await hre.run("verify:verify", {
      address: nouncillorsDescriptorAddress,
      constructorArguments: [initialOwner, nouncillorsArtAddress, svgRendererAddress]
    });

    // Verify NouncillorsArt
    await hre.run("verify:verify", {
      address: nouncillorsArtAddress,
      constructorArguments: [nouncillorsDescriptorAddress, inflatorAddress]
    });

    // Verify NouncillorsToken
    await hre.run("verify:verify", {
      address: nouncillorsTokenAddress,
      constructorArguments: [initialOwner, "Nouncillors", "NC", erc2771ForwarderAddress, nouncillorsDescriptorAddress]
    });
    
    console.log("Contracts verified successfully!");

  } catch (error) {
    console.error("Verification failed:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
