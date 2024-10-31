// VoteOnProposal.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { NouncilDAOProxy } from "../contracts/governance/NouncilDAOProxy.sol";

contract VoteOnProposalScript is Script {
    address public constant PROXY_ADDRESS = 0x8097173bCA40971642E3A780aAd420a45E8Cb610;

    function run() external {
        uint256 voterPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(voterPrivateKey);

        NouncilDAOProxy proxy = NouncilDAOProxy(PROXY_ADDRESS);

        uint256 proposalId = /* The proposal ID from the previous step */;
        uint8 support = 1; // 0 = Against, 1 = For, 2 = Abstain

        proxy.castVote(proposalId, support);

        console.log("Vote cast for proposal ID:", proposalId);

        vm.stopBroadcast();
    }
}
