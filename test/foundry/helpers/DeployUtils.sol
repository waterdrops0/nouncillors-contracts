// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { DescriptorHelpers } from './DescriptorHelpers.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { NouncilDAOExecutor } from '../../../contracts/governance/NouncilDAOExecutor.sol';
import { NouncilDAOLogic } from '../../../contracts/governance/NouncilDAOLogic.sol';
import { NouncilDAOProxy } from '../../../contracts/governance/NouncilDAOProxy.sol';
import { ERC1967Proxy } from '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import { IProxyRegistry } from '../../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncillorsToken } from '../../../contracts/NouncillorsToken.sol';
import { NouncilDAOStorageV1 } from '../../../contracts/governance/NouncilDAOInterfaces.sol';

abstract contract DeployUtils is Test, DescriptorHelpers {
    uint256 constant TIMELOCK_DELAY = 2 days;
    uint256 constant VOTING_PERIOD = 7_200; // 24 hours
    uint256 constant VOTING_DELAY = 1;
    uint256 constant PROPOSAL_THRESHOLD = 1;
    uint256 constant QUORUM_VOTES_BPS = 2000;

    uint32 constant LAST_MINUTE_BLOCKS = 10;
    uint32 constant OBJECTION_PERIOD_BLOCKS = 10;
    uint32 constant UPDATABLE_PERIOD_BLOCKS = 10;

    function _deployAndPopulateDescriptor() internal returns (NouncillorsDescriptor) {
        NouncillorsDescriptor descriptor = _deployDescriptor();
        _populateDescriptor(descriptor);
        return descriptor;
    }

    function deployToken(address initialOwner) internal returns (NouncillorsToken nouncillorsToken) {
        IProxyRegistry proxyRegistry = IProxyRegistry(address(3));
        NouncillorsDescriptor descriptor = _deployAndPopulateDescriptor();

        string memory tokenName = "Nouncillors";
        string memory tokenSymbol = "NCL";
        address trustedForwarder = address(0); 

        nouncillorsToken = new NouncillorsToken(
            initialOwner,       // initialOwner
            tokenName,          // name
            tokenSymbol,        // symbol
            trustedForwarder,   // trustedForwarder
            descriptor          // descriptor
        );

        return nouncillorsToken;
    }

    struct NouncilDAOParams {
        uint256 votingPeriod;
        uint256 votingDelay;
        uint256 proposalThresholdBPS;
        uint256 quorumVotesBPS;
        address timelock;
        address admin;
        address implementation;
    }

    function _deployDAOWithParams() internal returns (NouncilDAOLogic) {
        NouncilDAOExecutor timelock;
        NouncillorsToken nouncillorsToken;

        timelock = NouncilDAOExecutor(payable(address(new ERC1967Proxy(address(new NouncilDAOExecutor(address(1), TIMELOCK_DELAY)), ''))));

        nouncillorsToken = deployToken(makeAddr('initialOwner'));

        nouncillorsToken.transferOwnership(address(timelock));

        address daoLogicImplementation = address(new NouncilDAOLogic());

        NouncilDAOLogic dao = NouncilDAOLogic(
            payable(
                new NouncilDAOProxy(
                    address(timelock),
                    address(nouncillorsToken),
                    makeAddr('vetoer'),
                    address(this),
                    daoLogicImplementation,
                    VOTING_PERIOD,
                    VOTING_DELAY,
                    PROPOSAL_THRESHOLD,
                    QUORUM_VOTES_BPS
                )
            )
        );

        vm.prank(address(timelock));
        timelock.setPendingAdmin(address(dao));
        vm.prank(address(dao));
        timelock.acceptAdmin();

        return dao;
    }

    function _deployDAO() internal returns (NouncilDAOLogic) {
        return _deployDAOWithParams();
    }

    function get1967Implementation(address proxy) internal view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        return address(uint160(uint256(vm.load(proxy, slot))));
    }
}