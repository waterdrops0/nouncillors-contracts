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

interface INouncillorsToken is IERC721 {
    event NouncillorMinted(uint256 indexed tokenId, Seed seed, address indexed minter);

    event DescriptorUpdated(INouncillorsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event WhitelistUpdated(bytes32 indexed newMerkleRoot);
    
    event TransferabilityToggled(bool transfersEnabled);

    error NotWhitelisted();

    error AlreadyClaimed();

    error TransferDisabled();

    error DescriptorisLocked();

    function mint(bytes32[] calldata _merkleProof, Seed calldata _seed) external returns (uint256);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDescriptor(INouncillorsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;
}