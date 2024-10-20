// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { NouncillorsToken } from '../../contracts/NouncillorsToken.sol';
import { INouncillorsToken } from '../../contracts/interfaces/INouncillorsToken.sol';
import { NouncillorsDescriptor } from '../../contracts/NouncillorsDescriptor.sol';
import { IProxyRegistry } from '../../contracts/external/opensea/IProxyRegistry.sol';
import { SVGRenderer } from '../../contracts/SVGRenderer.sol';
import { NouncillorsArt } from '../../contracts/NouncillorsArt.sol';
import { DeployUtils } from './helpers/DeployUtils.sol';

contract NouncillorsTokenTest is Test, DeployUtils {
    address owner = address(1);

    // Custom error from OpenZeppelin's Ownable.sol that can't be called from the ABI of NouncillorsToken.sol
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        nouncillorsToken = deployToken(owner);
    }

    function testSymbol() public {
        assertEq(nouncillorsToken.symbol(), 'NCL');
    }

    function testName() public {
        assertEq(nouncillorsToken.name(), 'Nouncillors');
    }

    function testMintANouncillorToSelf() public {
        INouncillorsToken.Seed memory seed = INouncillorsToken.Seed({
        background: 0,
        body: 0,
        accessory: 0,
        head: 0,
        glasses: 0
        });

        vm.prank(owner);
        nouncillorsToken.mint(seed, owner);

        assertEq(nouncillorsToken.ownerOf(0), owner);
    }

    function testRevertsOnNotMinterMint() public {
        INouncillorsToken.Seed memory seed = INouncillorsToken.Seed({
        background: 0,
        body: 0,
        accessory: 0,
        head: 0,
        glasses: 0
        });

        address unauthorized = address(2);

        // Prank with unauthorized address
        vm.prank(unauthorized);

        // Expect revert from unauthorized address
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, unauthorized));

        // Try to mint
        nouncillorsToken.mint(seed, unauthorized);
    }
}