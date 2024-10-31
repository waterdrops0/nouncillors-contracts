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
    
    address constant ELIGIBLE_MINTER = 0xbE41e1Dd8C970AC40E8aB284CDd581e3b35Da51C;
    bytes32[] proof;  // Declare proof as a dynamic array
    Utils utils;


    function setUp() public {

        // Initialize the Utils contract
        utils = new Utils();

        // Initialize the proof array and add values
        proof = new bytes32;
        proof[0] = 0x4b278523b883e4b3d15629ad062f13fb62c1bc225781c30cca13861e9a5f480b;
        proof[1] = 0x9b122a13601b95f977cb37e57f910f81aa61acb0cf6efac1055afc7251ed7972;
        proof[2] = 0xf282b23d8264633a7a2a88788206209e6204dca7dc00b2d06d1ccc4cca0fb003;
        proof[3] = 0xcf4945e90e80472a38b615d09e10e11e804c9280e670c4599a760a00599cbdc0;
        proof[4] = 0x6e58cef1d0d83510de4741426a566e556ec4bfc26c4406d8129e197ef2f02896;
        proof[5] = 0x7e407f3697933c7c3ff1022064d6bf08432578408b6b3f7b4ebf3f65abae80f3;

        NouncillorsDescriptor descriptor = _deployAndPopulateDescriptor();

        nouncillorsToken = new NouncillorsToken(INITIAL_OWNER, "Nouncillors", "NCL", address(0), descriptor);

        // Deploy the NouncilDAOLogic implementation contract
        NouncilDAOLogic logic = new NouncilDAOLogic();

        // Deploy the NouncilDAOProxy contract
        NouncilDAOProxy daoProxy = new NouncilDAOProxy(
            address(timelock),  // Timelock address
            address(nouncillorsToken),
            VETOER,
            address(this),  // admin (initially set as test deployer)
            address(logic),
            VOTING_PERIOD,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD_BPS,
            QUORUM_VOTES_BPS
        );

        // Assign `dao` to point to the proxy, cast to `NouncilDAOLogic`
        dao = NouncilDAOLogic(address(daoProxy));

        // Transfer the admin role from the deployer to the daoProxy
        vm.prank(address(timelock));
        timelock.setPendingAdmin(address(daoProxy));

        // Simulate daoProxy accepting the admin role
        vm.prank(address(daoProxy));
        timelock.acceptAdmin();

        // Ensure that the timelock is correctly set
        require(address(dao.timelock()) == address(timelock), "Timelock not set properly");

        // Mint tokens for the proposer
        mint(PROPOSER, 1);

        mintWithProof(proof);

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
        address againstVoter = utils.getNextUserAddress();

        mint(forVoter1, 1);
        mint(forVoter2, 1);
        mint(againstVoter, 1);

        uint256 proposalId = propose(address(0x1234), 100, '', '');

        startVotingPeriod();
        vote(forVoter1, proposalId, 1);
        vote(forVoter2, proposalId, 1);
        vote(againstVoter, proposalId, 0);
        endVotingPeriod();

        // Debugging: Check that the timelock is set in the DAO
        console.log("DAO Timelock Address: ", address(dao.timelock()));
        require(address(dao.timelock()) != address(0), "Timelock not initialized in DAO");

        // Queue the proposal
        dao.queue(proposalId);

        // Debugging: Log the grace period to ensure it's accessible
        console.log("Timelock Grace Period: ", timelock.GRACE_PERIOD());

        // Debugging: Check the timelock address in queueTransaction call
        console.log("Checking timelock reference in queueTransaction");

        // Warp forward in time to expire the proposal
        vm.warp(block.timestamp + timelock.delay() + timelock.GRACE_PERIOD() + 10);

        // Ensure the proposal state is 'Expired'
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
