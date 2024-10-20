// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';
import { NouncilDAOLogic } from '../../contracts/governance/NouncilDAOLogic.sol';
import { NouncilDAOProxy } from '../../contracts/governance/NouncilDAOProxy.sol';
import { NouncilDAOStorageV1 } from '../../contracts/governance/NouncilDAOInterfaces.sol';
import { NouncillorsDescriptor } from '../../contracts/NouncillorsDescriptor.sol';
import { NouncillorsToken } from '../../contracts/NouncillorsToken.sol';
import { IProxyRegistry } from '../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncilDAOExecutor } from '../../contracts/governance/NouncilDAOExecutor.sol';
import { DeployUtils } from './helpers/DeployUtils.sol';


contract NouncilDAOLogicState is Test, DeployUtils {

    function setUp() public {

        NouncillorsDescriptor descriptor = _deployAndPopulateDescriptor();

    
        nouncillorsToken = new NouncillorsToken(INITIAL_OWNER, "Nouncillors", "NCL", address(0), descriptor);


        // Deploy the NouncilDAOExecutor (timelock) contract and get its address
        address timelockAddress = address(new NouncilDAOExecutor(ADMIN, TIMELOCK_DELAY));


        // Deploy the NouncilDAOProxy contract using addresses instead of contract instances
        NouncilDAOProxy daoProxy = new NouncilDAOProxy(
            timelockAddress,
            address(nouncillorsToken),
            VETOER,
            address(this),
            address(new NouncilDAOLogic()),
            VOTING_PERIOD,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD_BPS,
            QUORUM_VOTES_BPS
        );


        // Assign `dao` to point to the proxy, cast to `NouncilDAOLogic`
        dao = NouncilDAOLogic(address(daoProxy));

        mint(PROPOSER, 1);

        vm.roll(block.number +1);

        nouncillorsToken.ownerOf(0);

        nouncillorsToken.votesToDelegate(PROPOSER);
        
        vm.prank(PROPOSER);
        nouncillorsToken.delegate(PROPOSER);

        vm.roll(block.number +1);
 

        nouncillorsToken.getPriorVotes(PROPOSER, block.number - 1);
        nouncillorsToken.getCurrentVotes(PROPOSER);

        // If needed, advance time and blocks further
        vm.roll(block.number + 10);

    }

    function propose(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) internal returns (uint256 proposalId) {
        vm.prank(PROPOSER);
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;
        string[] memory signatures = new string[](1);
        signatures[0] = signature;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;
        
        proposalId = dao.propose(targets, values, signatures, calldatas, 'my proposal');
    }


    function testRevertsGivenProposalIdThatDoesntExist() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        uint256 state = uint256(NouncilDAOLogic(address(daoProxy)).state(proposalId));

        vm.expectRevert('NouncilDAO::state: invalid proposal id');
        // Cast `daoProxy` to `NouncilDAOLogic` when calling `state`
        NouncilDAOLogic(address(daoProxy)).state(proposalId + 1);
    }


    function testPendingGivenProposalJustCreated() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        // Cast `daoProxy` to `NouncilDAOLogic` to access the `state` function
        uint256 state = uint256(NouncilDAOLogic(address(daoProxy)).state(proposalId));
        console.log("Proposal State after creation: ", state);

        // Use the same casting in the assertion
        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Pending
        );
    }

    function testActiveGivenProposalPastVotingDelay() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = NouncilDAOLogic(address(daoProxy)).votingDelay();
        vm.roll(block.number + votingDelay + 1);
        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Active
        );
    }


    function testCanceledGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        NouncilDAOLogic(address(daoProxy)).cancel(proposalId);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled
        );
    }



    function testDefeatedByRunningOutOfTime() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = NouncilDAOLogic(address(daoProxy)).votingDelay();
        uint256 votingPeriod = NouncilDAOLogic(address(daoProxy)).votingPeriod();
        vm.roll(block.number + votingDelay + votingPeriod + 1);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );
    }


    function testDefeatedByVotingAgainst() public {
        address forVoter = utils.getNextUserAddress();
        address againstVoter = utils.getNextUserAddress();
        mint(forVoter, 3);
        mint(againstVoter, 3);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );
    }

    function testSucceeded() public {
        address forVoter = utils.getNextUserAddress();
        address againstVoter = utils.getNextUserAddress();
        mint(forVoter, 4);
        mint(againstVoter, 3);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Succeeded
        );
    }

    function testQueueRevertsGivenDefeatedProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = NouncilDAOLogic(address(daoProxy)).votingDelay();
        uint256 votingPeriod = NouncilDAOLogic(address(daoProxy)).votingPeriod();
        vm.roll(block.number + votingDelay + votingPeriod + 1);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        NouncilDAOLogic(address(daoProxy)).queue(proposalId);
    }

    function testQueueRevertsGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        NouncilDAOLogic(address(daoProxy)).cancel(proposalId);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled
        );

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        NouncilDAOLogic(address(daoProxy)).queue(proposalId);
    }

    function testQueued() public {
        address forVoter = utils.getNextUserAddress();
        address againstVoter = utils.getNextUserAddress();
        mint(forVoter, 4);
        mint(againstVoter, 3);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();

        // anyone can queue
        NouncilDAOLogic(address(daoProxy)).queue(proposalId);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Queued
        );
    }

    function testExpired() public {
        address forVoter = utils.getNextUserAddress();
        address againstVoter = utils.getNextUserAddress();
        mint(forVoter, 4);
        mint(againstVoter, 3);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();
        NouncilDAOLogic(address(daoProxy)).queue(proposalId);

        // Ensure `timelock` is properly initialized
        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Expired
        );
    }

    function testExecutedOnlyAfterQueued() public {
        address forVoter = utils.getNextUserAddress();
        mint(forVoter, 4);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        NouncilDAOLogic(address(daoProxy)).execute(proposalId);

        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        NouncilDAOLogic(address(daoProxy)).execute(proposalId);

        endVotingPeriod();
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        NouncilDAOLogic(address(daoProxy)).execute(proposalId);

        NouncilDAOLogic(address(daoProxy)).queue(proposalId);
        vm.expectRevert("NouncilDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock.");
        NouncilDAOLogic(address(daoProxy)).execute(proposalId);

        vm.warp(block.timestamp + timelock.delay() + 1);
        vm.deal(address(timelock), 100);
        NouncilDAOLogic(address(daoProxy)).execute(proposalId);

        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed
        );

        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);
        assertTrue(
            NouncilDAOLogic(address(daoProxy)).state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed
        );
    }
}
