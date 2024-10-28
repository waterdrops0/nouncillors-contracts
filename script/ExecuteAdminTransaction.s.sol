// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NouncilDAOExecutor} from "../contracts/governance/NouncilDAOExecutor.sol";
import {NouncilDAOProxy} from "../contracts/governance/NouncilDAOProxy.sol";

contract ExecuteAdminTransaction is Script {
    address public constant EXECUTOR_ADDRESS = 0xfc91fA66C06Ec6D086Da7C377e4403Fb51dB0474;
    address public constant PROXY_ADDRESS = 0x8097173bCA40971642E3A780aAd420a45E8Cb610;
    uint256 public constant ETA = 1729952460;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NouncilDAOExecutor executor = NouncilDAOExecutor(payable(EXECUTOR_ADDRESS));
        bytes memory data = abi.encodeWithSignature("setPendingAdmin(address)", PROXY_ADDRESS);

        // Calculate the txHash for the queued transaction
        bytes32 txHash = keccak256(
            abi.encode(EXECUTOR_ADDRESS, 0, "", data, ETA)
        );

        console.log("Current block timestamp:", block.timestamp);
        console.log("ETA:", ETA);

        // Check if the transaction is queued
        bool isQueued = executor.queuedTransactions(txHash);
        console.log("Is transaction queued:", isQueued);

        // Execute the transaction
        executor.executeTransaction(
            EXECUTOR_ADDRESS,
            0,
            "",
            data,
            ETA
        );
        console.log("Pending admin transaction executed successfully.");

        // Step 2: Check if pendingAdmin is set correctly
        (bool success, bytes memory returnData) = address(PROXY_ADDRESS).staticcall(
            abi.encodeWithSignature("pendingAdmin()")
        );

        require(success, "Failed to retrieve pendingAdmin");
        address pendingAdmin = abi.decode(returnData, (address));
        console.log("Pending Admin set to:", pendingAdmin);

        // Verify if pendingAdmin is correctly set to PROXY_ADDRESS
        require(pendingAdmin == PROXY_ADDRESS, "pendingAdmin was not set correctly.");

        // Step 3: Accept admin role
        (bool successAccept, ) = address(PROXY_ADDRESS).call(abi.encodeWithSignature("_acceptAdmin()"));
        require(successAccept, "NouncilDAOProxy failed to accept the admin role.");

        console.log("NouncilDAOProxy has accepted the admin role of NouncilDAOExecutor.");

        vm.stopBroadcast();
    }
}
