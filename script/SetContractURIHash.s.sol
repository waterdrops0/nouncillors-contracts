// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface NouncillorsToken {
    function setContractURIHash(string memory newContractURIHash) external;
}

contract SetContractURIHash is Script {
    function run() external {
        // Sepolia Contract Address for NouncillorsToken.sol
        address nouncillorsTokenAddress = 0xfA4378Bf63FfAC00A8250FE69F23Dcb05539f694;

        // Interface to interact with the deployed contract
        NouncillorsToken nouncillorsToken = NouncillorsToken(nouncillorsTokenAddress);

        // Define the new contract URI hash
        string memory newContractURIHash = "QmNdUibRHNqX2byJLtCD3ofn65cfCtvXdQnV87wRjqWf96";

        // Start the broadcast to send the transaction
        vm.startBroadcast();

        // Call the setContractURIHash function on the deployed contract
        nouncillorsToken.setContractURIHash(newContractURIHash);

        // Stop the broadcast after the transaction is sent
        vm.stopBroadcast();
    }
}

