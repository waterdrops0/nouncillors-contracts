// SPDX-License-Identifier: MIT

/// @title Interface for NouncillorsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './INouncillorsDescriptorMinimal.sol';
import './INouncillorsSeeder.sol';

interface INouncillorsToken is IERC721 {
    event NouncillorCreated(uint256 indexed tokenId, INouncillorsSeeder.Seed seed);

    event NoucillorBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INouncillorsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INouncillorsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INouncillorsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INouncillorsSeeder seeder) external;

    function lockSeeder() external;
}