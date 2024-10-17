// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/NouncillorsToken.sol"; 

contract SetMerkleRoot is Script {
    function run() external {
        // Contract's address
        address nouncillorsTokenAddress = 0xdff7597707c5B216df6BbE0c5783A46b6a2D7aB7;

        // Initialize the deployed contract
        NouncillorsToken nouncillorsToken = NouncillorsToken(nouncillorsTokenAddress);

        // Insert the new Merkle root you generated here
        bytes32 rootBytes32 = 0x3078323331310000000000000000000000000000000000000000000000000000; 

        // Start broadcasting a transaction
        vm.startBroadcast();

        // Set the Merkle root
        nouncillorsToken.setMerkleRoot(rootBytes32);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
