const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const AddressData = require('../files/addresses.json');

const addresses = AddressData.addresses;

// Hash the addresses
const leaves = addresses.map(addr => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Generate and save proofs for each address
let proofs = {};
addresses.forEach(address => {
    const leaf = keccak256(address);
    const proof = tree.getProof(leaf).map(p => '0x' + p.data.toString('hex').padStart(64, '0'));
    proofs[address] = proof;
});

// Output to the current directory
fs.writeFileSync('./files/merkleProofs.json', JSON.stringify(proofs, null, 2));

console.log('Merkle Proofs saved to merkleProofs.json');
