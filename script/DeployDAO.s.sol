// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NouncilDAOLogic} from "../contracts/governance/NouncilDAOLogic.sol";
import {NouncilDAOExecutor} from "../contracts/governance/NouncilDAOExecutor.sol";
import {NouncilDAOProxy} from "../contracts/governance/NouncilDAOProxy.sol";

contract DeployDAO is Script {
    // Declare all constants
    address public constant NOUNCILLORS_ADDRESS = 0x8D047492Adfbb94C6cD48300b5df5e7872Ad0C40;
    address public constant VETOER_ADDRESS = 0xbE41e1Dd8C970AC40E8aB284CDd581e3b35Da51C;
    address public constant INITIAL_ADMIN_ADDRESS = 0xbE41e1Dd8C970AC40E8aB284CDd581e3b35Da51C;
    
    uint256 public constant VOTING_PERIOD = 7_200; // 24 hours
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant PROPOSAL_THRESHOLD_BPS = 1;
    uint256 public constant QUORUM_VOTES_BPS = 2000;
    uint256 public constant DELAY = 2 days; 

    function run() external {
        // Fetch the private key of the deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NouncilDAOExecutor contract
        NouncilDAOExecutor executor = new NouncilDAOExecutor(INITIAL_ADMIN_ADDRESS, DELAY);
        console.log("NouncilDAOExecutor deployed at:", address(executor));


        // Deploy NouncilDAOLogic contract
        NouncilDAOLogic logic = new NouncilDAOLogic();
        console.log("NouncilDAOLogic deployed at:", address(logic));


        // Deploy NouncilDAOProxy contract
        NouncilDAOProxy proxy = new NouncilDAOProxy(
            address(executor),
            NOUNCILLORS_ADDRESS,
            VETOER_ADDRESS,
            INITIAL_ADMIN_ADDRESS,
            address(logic),
            VOTING_PERIOD,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD_BPS,
            QUORUM_VOTES_BPS
        );
        console.log("NouncilDAOProxy deployed at:", address(proxy));

        // Step 1: Queue the setPendingAdmin transaction via the NouncilDAOExecutor
        bytes memory data = abi.encodeWithSignature("setPendingAdmin(address)", address(proxy));
        
        // Calculate eta as block.timestamp + delay + buffer time (just in case)
        uint256 eta = block.timestamp + DELAY + 60; // Adding an extra 60 seconds buffer to avoid timing issues
        executor.queueTransaction(address(executor), 0, "", data, eta);
        console.log("Transaction to setPendingAdmin queued with eta:", eta);

        // Stop broadcasting transactions
        vm.stopBroadcast();
        console.log("Deployment complete. Please execute the transaction after the timelock delay.");
    }
}
