const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { ethers } = require('ethers');

const addresses = [
    '0xAddress1...',
    '0xAddress2...',
    // ... more addresses
];

// Smart contract details
const contractAddress = 'YOUR_CONTRACT_ADDRESS';
const contractABI = 'YOUR_CONTRACT_ABI'; // Replace with your contract's ABI
const privateKey = 'YOUR_PRIVATE_KEY';   // Owner's private key (keep it secure!)

// Connect to Ethereum
const provider = new ethers.providers.JsonRpcProvider('YOUR_INFURA_URL');
const wallet = new ethers.Wallet(privateKey, provider);
const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// Create a Merkle tree
const leaves = addresses.map(addr => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = tree.getRoot();

// Function to update Merkle root in the contract
async function updateMerkleRoot(root) {
    try {
        const tx = await contract.setMerkleRoot(root);
        console.log('Transaction hash:', tx.hash);
        await tx.wait();
        console.log('Merkle root updated successfully');
    } catch (error) {
        console.error('Failed to update Merkle root:', error);
    }
}

// Update Merkle root in the smart contract
updateMerkleRoot(root);
