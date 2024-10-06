// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { NouncillorsToken } from '../../contracts/NouncillorsToken.sol';
import { NouncillorsDescriptorV2 } from '../../contracts/NouncillorsDescriptor.sol';
import { IProxyRegistry } from '../../contracts/external/opensea/IProxyRegistry.sol';
import { SVGRenderer } from '../../contracts/SVGRenderer.sol';
import { NouncillorsArt } from '../../contracts/NouncillorsArt.sol';
import { DeployUtils } from './helpers/DeployUtils.sol';

contract NouncillorsTokenTest is Test, DeployUtils {
    NouncillorsToken nouncillorsToken;
    address owner = address(1);
    address minter = address(2);

    function setUp() public {
        NouncillorsDescriptorV2 descriptor = _deployAndPopulateV2();
        _populateDescriptorV2(descriptor);

        nouncillorsToken = new NouncillorsToken(owner, minter, descriptor, IProxyRegistry(address(0)));
    }

    function testSymbol() public {
        assertEq(nouncillorsToken.symbol(), 'NOUNC');
    }

    function testName() public {
        assertEq(nouncillorsToken.name(), 'Nouncillors');
    }

    function testMintANounToSelfAndRewardsNoundersDao() public {
        vm.prank(minter);
        nouncillorsToken.mint();

        assertEq(nouncillorsToken.ownerOf(0), owner);
        assertEq(nouncillorsToken.ownerOf(1), minter);
    }

    function testRevertsOnNotMinterMint() public {
        vm.expectRevert('Sender is not the minter');
        nouncillorsToken.mint();
    }
}