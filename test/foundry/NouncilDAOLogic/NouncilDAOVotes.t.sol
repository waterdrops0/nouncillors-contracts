// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';
import { NouncilDAOLogicBaseTest } from './NouncilDAOLogicBaseTest.sol';
import { NouncilDAOVotes } from '../../../contracts/governance/NouncilDAOVotes.sol';
import { NouncilDAOTypes } from '../../../contracts/governance/NouncilDAOInterfaces.sol';

contract NouncilDAOLogicVotesTest is NouncilDAOLogicBaseTest {
    address proposer = makeAddr('proposer');
    address voter = makeAddr('voter');
    uint256 proposalId;

    function setUp() public override {
        super.setUp();

        mintTo(proposer);
        mintTo(proposer);
        mintTo(voter);

        assertTrue(nouncillorsToken.getCurrentVotes(proposer) > dao.proposalThreshold());
        proposalId = propose(proposer, proposer, 0.01 ether, '', '', '');
    }

    function test_duringObjectionPeriod_givenForVote_reverts() public {
        // go into last minute
        vm.roll(
            block.number +
                dao.proposalUpdatablePeriodInBlocks() +
                dao.votingDelay() +
                dao.votingPeriod() -
                dao.lastMinuteWindowInBlocks() +
                1
        );

        // trigger objection period
        vm.prank(proposer);
        dao.castVote(proposalId, 1);

        // go into objection period
        vm.roll(block.number + dao.lastMinuteWindowInBlocks());
        assertTrue(dao.state(proposalId) == NouncilDAOTypes.ProposalState.ObjectionPeriod);

        vm.expectRevert(NouncilDAOVotes.CanOnlyVoteAgainstDuringObjectionPeriod.selector);
        vm.prank(voter);
        dao.castVote(proposalId, 1);
    }

    function test_givenStateUpdatable_reverts() public {
        vm.startPrank(voter);
        assertTrue(dao.state(proposalId) == NouncilDAOTypes.ProposalState.Updatable);

        vm.expectRevert('NouncilDAO::castVoteInternal: voting is closed');
        dao.castVote(proposalId, 1);
    }

    function test_givenStatePending_reverts() public {
        vm.startPrank(voter);

        vm.roll(block.number + dao.proposalUpdatablePeriodInBlocks() + 1);
        assertTrue(dao.state(proposalId) == NouncilDAOTypes.ProposalState.Pending);

        vm.expectRevert('NouncilDAO::castVoteInternal: voting is closed');
        dao.castVote(proposalId, 1);
    }

    function test_givenStateDefeated_reverts() public {
        vm.startPrank(voter);

        vm.roll(block.number + dao.proposalUpdatablePeriodInBlocks() + dao.votingDelay() + dao.votingPeriod() + 1);
        assertTrue(dao.state(proposalId) == NounsDAOTypes.ProposalState.Defeated);

        vm.expectRevert('NouncilDAO::castVoteInternal: voting is closed');
        dao.castVote(proposalId, 1);
    }

    function test_givenStateSucceeded_reverts() public {
        vm.startPrank(voter);

        vm.roll(block.number + dao.proposalUpdatablePeriodInBlocks() + dao.votingDelay() + 1);
        assertTrue(dao.state(proposalId) == NouncilDAOTypes.ProposalState.Active);

        dao.castVote(proposalId, 1);

        vm.roll(block.number + dao.votingPeriod());
        assertTrue(dao.state(proposalId) == NouncilDAOTypes.ProposalState.Succeeded);

        vm.expectRevert('NouncilDAO::castVoteInternal: voting is closed');
        dao.castVote(proposalId, 1);
    }

    function test_givenStateQueued_reverts() public {
        vm.startPrank(voter);

        // Get the proposal to succeeded state
        vm.roll(block.number + dao.proposalUpdatablePeriodInBlocks() + dao.votingDelay() + 1);
        dao.castVote(proposalId, 1);
        vm.roll(block.number + dao.votingPeriod());

        dao.queue(proposalId);

        changePrank(proposer);
        vm.expectRevert('NouncilDAO::castVoteInternal: voting is closed');
        dao.castVote(proposalId, 1);
    }
}