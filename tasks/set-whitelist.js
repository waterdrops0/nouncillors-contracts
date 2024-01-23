const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { ethers } = require("hardhat");

async function main() {
    const addresses = [
    '0x123',
    '0x1234',
];

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
  const nouncillorsTokenAddress = "";
  const nouncillorsToken = NouncillorsToken.attach(nouncillorsTokenAddress);

  try {
    const seed = await nouncillorsToken.setMerkleRoot(rootBytes32);
    console.log(`Updated the Merkle Root for whitelisting.`);
  } catch (error) {
    console.error("Error fetching value:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});