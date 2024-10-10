// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { INouncillorsToken } from '../../contracts/interfaces/INouncillorsToken.sol';
import { NouncilDAOLogic } from '../../contracts/governance/NouncilDAOLogic.sol';


contract InitializersLocked is Test {

    function test_NouncilDAOLogic_locks_initializer() public {
        NouncilDAOLogic c = new NouncilDAOLogic();
        vm.expectRevert('Initializable: contract is already initialized');
        c.initialize(address(0), address(1), address(3), 0, 0, 0, 0);
    }

    // Test for Forwarder to be added here

}
