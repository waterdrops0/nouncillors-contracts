// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';
import { NouncilDAOLogic } from '../../../contracts/governance/NouncilDAOLogic.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { NouncillorsToken } from '../../../contracts/NouncillorsToken.sol';
import { INouncillorsToken } from '../../../contracts/interfaces/INouncillorsToken.sol';
import { IProxyRegistry } from '../../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncilDAOExecutor } from '../../../contracts/governance/NouncilDAOExecutor.sol';
import { DeployUtils } from './DeployUtils.sol';
import { Utils } from './Utils.sol';

abstract contract NouncilDAOLogicHelpers is Test, DeployUtils {
    NouncilDAOLogic daoProxy;
    NouncillorsToken nouncillorsToken;
    NouncilDAOExecutor timelock = new NouncilDAOExecutor(address(1), TIMELOCK_DELAY);
    address vetoer = address(0x3);
    address admin = address(0x4);
    address nouncilDAO = address(0x6);
    address proposer = address(0x7);
    uint256 votingPeriod = 7200;
    uint256 votingDelay = 1;
    uint256 proposalThresholdBPS = 200;
    Utils utils;

    function deployDAOProxy(
        address timelock,
        address nouncillorsToken
    ) internal virtual returns (NouncilDAOLogic);

    function daoVersion() internal virtual returns (uint256) {
        return 0; // override to specify version
    }

    function propose(
        address _proposer,
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) internal returns (uint256 proposalId) {
        vm.prank(_proposer);
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

    function propose(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) internal returns (uint256 proposalId) {
        return propose(proposer, target, value, signature, data);
    }

    function mint(address to, uint256 amount) internal {

        INouncillorsToken.Seed memory seed = INouncillorsToken.Seed({
        background: 0,
        body: 0,
        accessory: 0,
        head: 0,
        glasses: 0
        });

        vm.startPrank(nouncilDAO);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = nouncillorsToken.mint_new(seed, address(this));
            nouncillorsToken.transferFrom(nouncilDAO, to, tokenId);
        }
        vm.stopPrank();
        vm.roll(block.number + 1);
    }

    function startVotingPeriod() internal {
        vm.roll(block.number + daoProxy.votingDelay() + 1);
    }

    function endVotingPeriod() internal {
        vm.roll(block.number + daoProxy.votingDelay() + daoProxy.votingPeriod() + 1);
    }

    function vote(address voter, uint256 proposalId, uint8 support) internal {
        vm.prank(voter);
        daoProxy.castVote(proposalId, support);
    }

}