// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NouncilDAOLogic} from "../contracts/governance/NouncilDAOLogic.sol";
import {NouncilDAOExecutor} from "../contracts/governance/NouncilDAOExecutor.sol";
import {NouncilDAOProxy} from "../contracts/governance/NouncilDAOProxy.sol";

contract DeployDAO is Script {
    function run() external {
        // Fetch the private key of the deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NouncilDAOLogic contract
        NouncilDAOLogic logic = new NouncilDAOLogic();
        console.log("NouncilDAOLogic deployed at:", address(logic));

        // Deploy NouncilDAOExecutor contract
        address admin_ = vm.envAddress("ADMIN_ADDRESS"); // Set admin address
        uint256 delay_ = vm.envUint("DELAY"); // Must be within MINIMUM_DELAY and MAXIMUM_DELAY
        NouncilDAOExecutor executor = new NouncilDAOExecutor(admin_, delay_);
        console.log("NouncilDAOExecutor deployed at:", address(executor));

        // Deploy NouncilDAOProxy contract
        address timelock_ = address(executor);
        address nouncillors_ = vm.envAddress("NOUNCILLORS_ADDRESS"); // Address of NOUNC tokens
        address vetoer_ = vm.envAddress("VETOER_ADDRESS"); // Vetoer address or zero address
        address adminProxy_ = vm.envAddress("ADMIN_PROXY_ADDRESS"); // Admin address for proxy
        address implementation_ = address(logic);
        uint256 votingPeriod_ = vm.envUint("VOTING_PERIOD"); // Within MIN_VOTING_PERIOD and MAX_VOTING_PERIOD
        uint256 votingDelay_ = vm.envUint("VOTING_DELAY"); // Within MIN_VOTING_DELAY and MAX_VOTING_DELAY
        uint256 proposalThresholdBPS_ = vm.envUint("PROPOSAL_THRESHOLD_BPS"); // Within allowed BPS range
        uint256 quorumVotesBPS_ = vm.envUint("QUORUM_VOTES_BPS"); // Within allowed BPS range

        NouncilDAOProxy proxy = new NouncilDAOProxy(
            timelock_,
            nouncillors_,
            vetoer_,
            adminProxy_,
            implementation_,
            votingPeriod_,
            votingDelay_,
            proposalThresholdBPS_,
            quorumVotesBPS_
        );
        console.log("NouncilDAOProxy deployed at:", address(proxy));

        // Stop broadcasting transactions
        vm.stopBroadcast();
        console.log("Deployment complete.");
    }
}
