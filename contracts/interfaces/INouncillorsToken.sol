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

pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './INouncillorsDescriptorMinimal.sol';
import './INouncillorsSeeder.sol';

interface INouncillorsToken is IERC721 {
    event NouncillorMinted(uint256 indexed tokenId, INouncillorsSeeder.Seed seed, address indexed minter);

    event DescriptorUpdated(INouncillorsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INouncillorsSeeder seeder);

    event SeederLocked();

    event WhitelistUpdated(bytes32 indexed newMerkleRoot);
    
    event TransferabilityToggled(bool transfersEnabled);

    error NotWhitelisted();

    error AlreadyClaimed();

    error TransferDisabled();

    error NonexistentTokenQuery(uint256 tokenId);

    error DescriptorLocked();

    error SeederLocked();

    function mint(bytes32[] calldata _merkleProof) external returns (uint256);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDescriptor(INouncillorsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INouncillorsSeeder seeder) external;

    function lockSeeder() external;
}