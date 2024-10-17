const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { ethers } = require("hardhat");
const AddressData = require('../files/addresses.json');

async function main() {
  // Access the addresses from the JSON file
  const addresses = AddressData.addresses;

  // Hash the addresses
  const leaves = addresses.map(addr => keccak256(addr));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // Get the Merkle root
  const root = tree.getRoot();

  // Convert root to bytes32 format
  const rootBytes32 = '0x' + root.toString('hex').padStart(64, '0');

  // Get the contract factory
  const NouncillorsToken = await ethers.getContractFactory("NouncillorsToken");

  // Attach to the address of the deployed contract
  const nouncillorsTokenAddress = "0xfA4378Bf63FfAC00A8250FE69F23Dcb05539f694";
  const nouncillorsToken = NouncillorsToken.attach(nouncillorsTokenAddress);

  try {
    const seed = await nouncillorsToken.setMerkleRoot(rootBytes32);
    console.log(`Updated the Merkle Root for whitelisting.`);
  } catch (error) {
    console.error("Error updating the Merkle root:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
