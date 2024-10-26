// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface NouncillorsToken {
    function setContractURIHash(string memory newContractURIHash) external;
}

contract SetContractURIHash is Script {
    function run() external {
        // Sepolia Contract Address for NouncillorsToken.sol
        address nouncillorsTokenAddress = 0x8D047492Adfbb94C6cD48300b5df5e7872Ad0C40;

        // Interface to interact with the deployed contract
        NouncillorsToken nouncillorsToken = NouncillorsToken(nouncillorsTokenAddress);

        // Define the new contract URI hash
        string memory newContractURIHash = "QmXUHY6xLYVL9SNcGQ7xVBxLyE6ZcKaJ9FohsHSFNgAL4E";

        // Start the broadcast to send the transaction
        vm.startBroadcast();

        // Call the setContractURIHash function on the deployed contract
        nouncillorsToken.setContractURIHash(newContractURIHash);

        // Stop the broadcast after the transaction is sent
        vm.stopBroadcast();
    }
}

