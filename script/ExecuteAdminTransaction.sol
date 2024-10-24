// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NouncilDAOExecutor} from "../contracts/governance/NouncilDAOExecutor.sol";

contract ExecuteAdminTransaction is Script {
    address public constant EXECUTOR_ADDRESS = 0xfc91fA66C06Ec6D086Da7C377e4403Fb51dB0474; // NouncilDAOExecutor address
    address public constant PROXY_ADDRESS = 0x8097173bCA40971642E3A780aAd420a45E8Cb610; // NouncilDAOProxy address
    uint256 public constant ETA = 1729952460; // Replace with the correct ETA from the queued transaction

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
