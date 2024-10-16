// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { DescriptorHelpers } from './DescriptorHelpers.sol';
import { DAOLogicHelpers } from './DAOLogicHelpers.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { NouncilDAOExecutor } from '../../../contracts/governance/NouncilDAOExecutor.sol';
import { NouncilDAOLogic } from '../../../contracts/governance/NouncilDAOLogic.sol';
import { NouncilDAOProxy } from '../../../contracts/governance/NouncilDAOProxy.sol';
import { ERC1967Proxy } from '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import { IProxyRegistry } from '../../../contracts/external/opensea/IProxyRegistry.sol';
import { NouncillorsToken } from '../../../contracts/NouncillorsToken.sol';
import { NouncilDAOStorageV1 } from '../../../contracts/governance/NouncilDAOInterfaces.sol';

abstract contract DeployUtils is Test, DescriptorHelpers, DAOLogicHelpers {

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


    function deployDAOProxy(
        address timelock,
        address nouncillorsToken
    ) internal returns (NouncilDAOProxy daoProxy) {
        daoProxy = new NouncilDAOProxy(
            timelock,
            nouncillorsToken,
            VETOER,
            address(this),
            address(new NouncilDAOLogic()),
            VOTING_PERIOD,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD_BPS,
            QUORUM_VOTES_BPS
        );
    }



    function deployDAOWithParams() internal returns (NouncilDAOLogic) {
        // Deploy the timelock without a proxy
        timelock = new NouncilDAOExecutor(ADMIN, TIMELOCK_DELAY);

        // Deploy the nouncillors token and transfer ownership to timelock
        nouncillorsToken = deployToken(INITIAL_OWNER);
        nouncillorsToken.transferOwnership(address(timelock));



        // Deploy the DAO proxy, passing in all necessary parameters
        NouncilDAOLogic dao = NouncilDAOLogic(
            payable(
                new NouncilDAOProxy(
                    address(timelock),
                    address(nouncillorsToken),
                    VETOER,
                    address(this), // The admin is the current contract
                    nouncilDAO,
                    VOTING_PERIOD,
                    VOTING_DELAY,
                    PROPOSAL_THRESHOLD_BPS,
                    QUORUM_VOTES_BPS
                )
            )
        );

        // Set the timelock admin to the DAO
        timelock.setPendingAdmin(address(dao));

        // Accept the admin role from the DAO
        vm.prank(address(dao));
        timelock.acceptAdmin();

        return dao;
    }



    function get1967Implementation(address proxy) internal view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        return address(uint160(uint256(vm.load(proxy, slot))));
    }
}