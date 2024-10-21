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
import { Utils } from './helpers/Utils.sol';


contract NouncilDAOLogicState is Test, DeployUtils {
    Utils utils;

    function setUp() public {
        // Initialize the Utils contract
        utils = new Utils();

        NouncillorsDescriptor descriptor = _deployAndPopulateDescriptor();

        nouncillorsToken = new NouncillorsToken(INITIAL_OWNER, "Nouncillors", "NCL", address(0), descriptor);

        // Deploy the NouncilDAOExecutor (timelock) contract with initial admin as the test deployer
        NouncilDAOExecutor timelock = new NouncilDAOExecutor(address(this), TIMELOCK_DELAY);

        // Deploy the NouncilDAOProxy contract
        NouncilDAOProxy daoProxy = new NouncilDAOProxy(
            address(timelock),  // Timelock address
            address(nouncillorsToken),
            VETOER,
            address(this),  // admin (initially set as test deployer)
            address(new NouncilDAOLogic()),
            VOTING_PERIOD,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD_BPS,
            QUORUM_VOTES_BPS
        );

        // Assign `dao` to point to the proxy, cast to `NouncilDAOLogic`
        dao = NouncilDAOLogic(address(daoProxy));

        vm.prank(address(timelock));

        // Transfer the admin role from the deployer to the daoProxy
        timelock.setPendingAdmin(address(daoProxy));

        // Simulate daoProxy accepting the admin role
        vm.prank(address(daoProxy));
        timelock.acceptAdmin();

        // Mint tokens for the proposer
        mint(PROPOSER, 1);

        // Roll forward to the next block
        vm.roll(block.number + 1);
    }

    function vote(address voter, uint256 proposalId, uint8 support) internal {
        vm.prank(voter);
        dao.castVote(proposalId, support);
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
        // Create a proposal and get the valid proposalId
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        // Advance the block number by 1 to pass the VOTING_DELAY
        vm.roll(block.number + 1);

        // Now check the state of the valid proposalId
        //uint256 state = uint256(NouncilDAOLogic(address(daoProxy)).state(proposalId));
        //console.log("State of valid proposal:", state);

        // Now test the invalid proposalId and expect a revert
        vm.expectRevert('NouncilDAO::state: invalid proposal id');
        
        // Calling state on proposalId + 1, which should not exist and should revert
        dao.state(proposalId + 1);
    }

    function testPendingGivenProposalJustCreated() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        console.log("Generated Proposal ID:", proposalId);

        // Cast `daoProxy` to `NouncilDAOLogic` to access the `state` function
        uint256 state = uint256(dao.state(proposalId));
        console.log("Proposal State after creation: ", state);

        // Use the same casting in the assertion
        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Pending
        );
    }

    function testActiveGivenProposalPastVotingDelay() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = dao.votingDelay();
        vm.roll(block.number + votingDelay + 1);
        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Active
        );
    }


    function testCanceledGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        dao.cancel(proposalId);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled
        );
    }



    function testDefeatedByRunningOutOfTime() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = dao.votingDelay();
        uint256 votingPeriod = dao.votingPeriod();
        vm.roll(block.number + votingDelay + votingPeriod + 1);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );
    }


    function testDefeatedByVotingAgainst() public {
        address forVoter = utils.getNextUserAddress();
        address againstVoter = utils.getNextUserAddress();
        mint(forVoter, 1);
        mint(againstVoter, 1);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );
    }

    function testSucceeded() public {
        address forVoter1 = utils.getNextUserAddress();
        address forVoter2 = utils.getNextUserAddress();
        address forVoter3 = utils.getNextUserAddress();
        address forVoter4 = utils.getNextUserAddress();
        address againstVoter1 = utils.getNextUserAddress();
        address againstVoter2 = utils.getNextUserAddress();
        address againstVoter3 = utils.getNextUserAddress();
        

        mint(forVoter1, 1);
        mint(forVoter2, 1);
        mint(forVoter3, 1);
        mint(forVoter4, 1);

        mint(againstVoter1, 1);
        mint(againstVoter2, 1);
        mint(againstVoter3, 1);

        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter1, proposalId, 1);
        vote(forVoter2, proposalId, 1);
        vote(forVoter3, proposalId, 1);
        vote(forVoter4, proposalId, 1);
        vote(againstVoter1, proposalId, 0);
        vote(againstVoter2, proposalId, 0);
        vote(againstVoter3, proposalId, 0);
        endVotingPeriod();

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Succeeded
        );
    }

    function testQueueRevertsGivenDefeatedProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        uint256 votingDelay = dao.votingDelay();
        uint256 votingPeriod = dao.votingPeriod();
        vm.roll(block.number + votingDelay + votingPeriod + 1);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Defeated
        );

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        dao.queue(proposalId);
    }

    function testQueueRevertsGivenCanceledProposal() public {
        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.prank(PROPOSER);
        dao.cancel(proposalId);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Canceled
        );

        vm.expectRevert('NouncilDAO::queue: proposal can only be queued if it is succeeded');
        dao.queue(proposalId);
    }

    function testQueued() public {
        address forVoter1 = utils.getNextUserAddress();
        address forVoter2 = utils.getNextUserAddress();
        address forVoter3 = utils.getNextUserAddress();
        address forVoter4 = utils.getNextUserAddress();
        address againstVoter1 = utils.getNextUserAddress();
        address againstVoter2 = utils.getNextUserAddress();
        address againstVoter3 = utils.getNextUserAddress();

        mint(forVoter1, 1);
        mint(forVoter2, 1);
        mint(forVoter3, 1);
        mint(forVoter4, 1);

        mint(againstVoter1, 1);
        mint(againstVoter2, 1);
        mint(againstVoter3, 1);


        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter1, proposalId, 1);
        vote(forVoter2, proposalId, 1);
        vote(forVoter3, proposalId, 1);
        vote(forVoter4, proposalId, 1);
        vote(againstVoter1, proposalId, 0);
        vote(againstVoter2, proposalId, 0);
        vote(againstVoter3, proposalId, 0);
        endVotingPeriod();

        // anyone can queue
        dao.queue(proposalId);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Queued
        );
    }

    function testExpired() public {
        address forVoter1 = utils.getNextUserAddress();
        address forVoter2 = utils.getNextUserAddress();
        address forVoter3 = utils.getNextUserAddress();
        address forVoter4 = utils.getNextUserAddress();
        address againstVoter1 = utils.getNextUserAddress();
        address againstVoter2 = utils.getNextUserAddress();
        address againstVoter3 = utils.getNextUserAddress();

        mint(forVoter1, 1);
        mint(forVoter2, 1);
        mint(forVoter3, 1);
        mint(forVoter4, 1);

        mint(againstVoter1, 1);
        mint(againstVoter2, 1);
        mint(againstVoter3, 1);


        uint256 proposalId = propose(address(0x1234), 100, '', '');
        startVotingPeriod();
        vote(forVoter1, proposalId, 1);
        vote(forVoter2, proposalId, 1);
        vote(forVoter3, proposalId, 1);
        vote(forVoter4, proposalId, 1);
        vote(againstVoter1, proposalId, 0);
        vote(againstVoter2, proposalId, 0);
        vote(againstVoter3, proposalId, 0);
        endVotingPeriod();
        dao.queue(proposalId);

        // Ensure `timelock` is properly initialized
        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Expired
        );
    }

    function testExecutedOnlyAfterQueued() public {
        address forVoter1 = utils.getNextUserAddress();
        address forVoter2 = utils.getNextUserAddress();
        address forVoter3 = utils.getNextUserAddress();
        address forVoter4 = utils.getNextUserAddress();

        mint(forVoter1, 1);
        mint(forVoter2, 1);
        mint(forVoter3, 1);
        mint(forVoter4, 1);


        uint256 proposalId = propose(address(0x1234), 100, '', '');
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        dao.execute(proposalId);

        startVotingPeriod();
        vote(forVoter1, proposalId, 1);
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        dao.execute(proposalId);

        endVotingPeriod();
        vm.expectRevert('NouncilDAO::execute: proposal can only be executed if it is queued');
        dao.execute(proposalId);

        dao.queue(proposalId);
        vm.expectRevert("NouncilDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock.");
        dao.execute(proposalId);

        vm.warp(block.timestamp + timelock.delay() + 1);
        vm.deal(address(timelock), 100);
        dao.execute(proposalId);

        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed
        );

        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 1);
        assertTrue(
            dao.state(proposalId) == NouncilDAOStorageV1.ProposalState.Executed
        );
    }
}
