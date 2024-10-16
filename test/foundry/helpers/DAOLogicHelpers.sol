// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';
import { NouncilDAOLogic } from '../../../contracts/governance/NouncilDAOLogic.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { NouncillorsToken } from '../../../contracts/NouncillorsToken.sol';
import { INouncillorsToken } from '../../../contracts/interfaces/INouncillorsToken.sol';
import { IProxyRegistry } from '../../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncilDAOExecutor } from '../../../contracts/governance/NouncilDAOExecutor.sol';
import { Utils } from './Utils.sol';

abstract contract DAOLogicHelpers is Test {
    
uint256 constant TIMELOCK_DELAY = 2 days;
uint256 constant VOTING_PERIOD = 7200; // 24 hours
uint256 constant VOTING_DELAY = 1;
uint256 constant PROPOSAL_THRESHOLD_BPS = 20;
uint256 constant QUORUM_VOTES_BPS = 2000;

// Predefined addresses
address constant VETOER = address(0x3);
address constant ADMIN = address(0x4);
address constant INITIAL_OWNER = address(0x5); 
address nouncilDAO = address(0x6);
address constant PROPOSER = address(0x7);

NouncilDAOLogic daoProxy;
NouncillorsToken nouncillorsToken;
NouncilDAOExecutor timelock;
Utils utils;


    function daoVersion() internal virtual returns (uint256) {
        return 0; // override to specify version
    }


    function mint(address to, uint256 amount) internal {

        INouncillorsToken.Seed memory seed = INouncillorsToken.Seed({
        background: 0,
        body: 0,
        accessory: 0,
        head: 0,
        glasses: 0
        });

        vm.startPrank(nouncilDAO);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = nouncillorsToken.mint_new(seed, to);
        }
        vm.stopPrank();
        vm.roll(block.number + 1);
    }

    function startVotingPeriod() internal {
        vm.roll(block.number + daoProxy.votingDelay() + 1);
    }

    function endVotingPeriod() internal {
        vm.roll(block.number + daoProxy.votingDelay() + daoProxy.votingPeriod() + 1);
    }

    function vote(address voter, uint256 proposalId, uint8 support) internal {
        vm.prank(voter);
        daoProxy.castVote(proposalId, support);
    }

}