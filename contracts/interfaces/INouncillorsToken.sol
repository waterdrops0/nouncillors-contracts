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
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    event NouncillorCreated(uint256 indexed tokenId, Seed seed, address indexed minter);

    event NouncillorBurned(uint256 indexed tokenId);

    event DescriptorUpdated(INouncillorsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event WhitelistUpdated(bytes32 indexed newMerkleRoot);
    
    event TransferabilityToggled(bool transfersEnabled);

    error InvalidSeedTrait(string trait, uint256 invalidValue, uint256 maxValue);

    error NotWhitelisted();

    error AlreadyClaimed();

    error TransferDisabled();

    error SenderisNotNouncilDAO();

    error DescriptorisLocked();

    function mintWithProof(bytes32[] calldata _merkleProof, Seed calldata _seed) external returns (uint256);

    function mint(Seed calldata _seed, address recipient) external returns (uint256);
    
    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDescriptor(INouncillorsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

}