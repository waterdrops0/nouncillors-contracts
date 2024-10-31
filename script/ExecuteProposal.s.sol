// ExecuteProposal.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { NouncilDAOProxy } from "../contracts/governance/NouncilDAOProxy.sol";

contract ExecuteProposalScript is Script {
    address public constant PROXY_ADDRESS = 0x8097173bCA40971642E3A780aAd420a45E8Cb610;

    function run() external {
        uint256 executorPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(executorPrivateKey);

        NouncilDAOProxy proxy = NouncilDAOProxy(PROXY_ADDRESS);

        uint256 proposalId = /* The proposal ID from the previous steps */;

        proxy.execute(proposalId);

        console.log("Proposal executed with ID:", proposalId);

        vm.stopBroadcast();
    }
}
