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
  const nouncillorsTokenAddress = "0x8D047492Adfbb94C6cD48300b5df5e7872Ad0C40";
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
