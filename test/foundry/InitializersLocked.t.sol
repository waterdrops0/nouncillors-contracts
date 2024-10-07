// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { NouncilDAOExecutor } from '../../contracts/governance/NouncilDAOExecutor.sol';
import { INouncillorsToken } from '../../contracts/interfaces/INouncillorsToken.sol';
import { NouncilDAOLogic } from '../../contracts/governance/NouncilDAOLogic.sol';


contract InitializersLocked is Test {
    function test_NouncilDAOExecutor_locks_initializer() public {
        NouncilDAOExecutor c = new NouncilDAOExecutor();
        vm.expectRevert('Initializable: contract is already initialized');
        c.initialize(address(0), 3 days);
    }

    function test_NouncilDAOLogic_locks_initializer() public {
        NouncilDAOLogic c = new NouncilDAOLogic();
        vm.expectRevert('Initializable: contract is already initialized');
        c.initialize(address(0), address(1), 0, 0, 0, 0, new address[](0), 0);
    }

    // Test for Forwarder to be added here

}
