// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { DescriptorHelpers } from './DescriptorHelpers.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { SVGRenderer } from '../../../contracts/SVGRenderer.sol';
import { NouncillorsArt } from '../../../contracts/NouncillorsArt.sol';
import { NouncilDAOExecutor } from '../../../contracts/governance/NouncilDAOExecutor.sol';
import { IProxyRegistry } from '../../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncillorsToken } from '../../../contracts/NouncillorsToken.sol';
import { Inflator } from '../../../contracts/Inflator.sol';


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
        NouncillorsDescriptor descriptor = new NouncillorsDescriptor();
        _populateDescriptor(descriptor);
        return descriptor;
    }

    function _deployAndPopulate() internal returns (NouncillorsDescriptor) {
        NouncillorsDescriptor descriptor = _deployDescriptor();
        _populateDescriptorV2(descriptor);
        return descriptor;
    }

    function _deployDescriptor() internal returns (NouncillorsDescriptor) {
        SVGRenderer renderer = new SVGRenderer();
        Inflator inflator = new Inflator();
        NouncillorsDescriptor descriptor = new NouncillorsDescriptor(NouncillorsArt(address(0)), renderer);
        NouncillorsArt art = new NouncillorsArt(address(descriptor), inflator);
        descriptor.setArt(art);
        return descriptor;
    }

    function deployToken(address nouncilDAO, address minter) internal returns (NouncillorsToken nouncillorsToken) {
        IProxyRegistry proxyRegistry = IProxyRegistry(address(3));
        NouncillorsDescriptor descriptor = _deployAndPopulate();

        nouncillorsToken = new NouncillorsToken(nouncilDAO, minter, descriptor);
    }

    function get1967Implementation(address proxy) internal view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        return address(uint160(uint256(vm.load(proxy, slot))));
    }
}