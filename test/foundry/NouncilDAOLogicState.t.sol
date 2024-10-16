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



        NouncilDAOLogic dao = deployDAOWithParams();
        mint(PROPOSER, 1);
        vm.roll(block.number + 1);
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
        
        proposalId = daoProxy.propose(targets, values, signatures, calldatas, 'my proposal');
    }


    function testRevertsGivenProposalIdThatDoesntExist() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        uint256 state = uint256(NouncilDAOLogic(payable(address(daoProxy))).state(proposalId));

        vm.expectRevert('NouncilDAO::state: invalid proposal id');
        daoProxy.state(proposalId + 1);
    }

    function testPendingGivenProposalJustCreated() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        uint256 state = uint256(NouncilDAOLogic(payable(address(daoProxy))).state(proposalId));
        console.log("Proposal State after creation: ", state);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Pending);
    }

    function testActiveGivenProposalPastVotingDelay() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.roll(block.number + daoProxy.votingDelay() + 1);
        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Active);
    }

    function testCanceledGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        daoProxy.cancel(proposalId);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled);
    }

    function testDefeatedByRunningOutOfTime() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.roll(block.number + daoProxy.votingDelay() + daoProxy.votingPeriod() + 1);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated);
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

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated);
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

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Succeeded);
    }

    function testQueueRevertsGivenDefeatedProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.roll(block.number + daoProxy.votingDelay() + daoProxy.votingPeriod() + 1);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated);

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        daoProxy.queue(proposalId);
    }

    function testQueueRevertsGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        daoProxy.cancel(proposalId);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled);

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        daoProxy.queue(proposalId);
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
        daoProxy.queue(proposalId);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Queued);
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
        daoProxy.queue(proposalId);
        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Expired);
    }

    function testExecutedOnlyAfterQueued() public {
        address forVoter = utils.getNextUserAddress();
        mint(forVoter, 4);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        daoProxy.execute(proposalId);

        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        daoProxy.execute(proposalId);

        endVotingPeriod();
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        daoProxy.execute(proposalId);

        daoProxy.queue(proposalId);
        vm.expectRevert("NouncilDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock.");
        daoProxy.execute(proposalId);

        vm.warp(block.timestamp + timelock.delay() + 1);
        vm.deal(address(timelock), 100);
        daoProxy.execute(proposalId);

        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed);

        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);
        assertTrue(daoProxy.state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed);
    }
}
