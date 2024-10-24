// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NouncilDAOExecutor} from "../contracts/governance/NouncilDAOExecutor.sol";

contract ExecuteAdminTransaction is Script {
    address public constant EXECUTOR_ADDRESS = 0x29CBD0398bB256B651B7d6427e2fDa2B825763cf; // NouncilDAOExecutor address
    address public constant PROXY_ADDRESS = 0xd8b3fDb6b59B30042dD136137292c821765d2E17; // NouncilDAOProxy address
    uint256 public constant ETA = 1729950396; // Replace with the correct ETA from the queued transaction

    function run() external {
        // Fetch the private key of the deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Execute the queued transaction to set the proxy as the pending admin
        NouncilDAOExecutor executor = NouncilDAOExecutor(payable(EXECUTOR_ADDRESS));
        bytes memory data = abi.encodeWithSignature("setPendingAdmin(address)", PROXY_ADDRESS);
        executor.executeTransaction(
            EXECUTOR_ADDRESS, // Target contract is the executor itself
            0,                // No ether is being sent
            "",               // No function signature, we use data directly
            data,             // Encoded data to set pending admin
            ETA               // Execution timestamp (must match the ETA used when queuing)
        );
        console.log("Pending admin transaction executed successfully.");

        // Step 2: Call acceptAdmin() from the NouncilDAOProxy to accept the admin role
        executor.acceptAdmin();
        console.log("NouncilDAOProxy has accepted the admin role of NouncilDAOExecutor.");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
