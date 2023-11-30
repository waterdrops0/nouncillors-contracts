// SPDX-License-Identifier: MIT

/// @title The Nouncillors ERC-721 token

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

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/INouncillorsDescriptorMinimal.sol";
import "./interfaces/INouncillorsSeeder.sol";
import './interfaces/INouncillorsToken.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ForwarderUpgradeable.sol";

contract NouncillorsToken is ERC2771ContextUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using MerkleProof for bytes32;

    // The descriptor contract that defines how Nouncillors NFTs should be displayed.
    INouncillorsDescriptorMinimal public descriptor;

    // The seeder contract that provides the randomness seed for NFTs.
    INouncillorsSeeder public seeder;

    // Mapping from token ID to its corresponding seed.
    mapping(uint256 => INouncillorsSeeder.Seed) public seeds;

    // Counter for the current token ID.
    uint256 private _currentNouncillorId;

    // Tracks whether an address has minted a token to enforce any minting restrictions.
    mapping(address => bool) private hasMinted;

    // Flag to control whether transfers are enabled or not.
    bool private _transfersEnabled;

    // Merkle root for verifying some aspect of the contract (e.g., whitelist).
    bytes32 private merkleRoot;

    // URI hash part of the contract metadata.
    string private _contractURIHash = 'EjsnYhfWQdasdACASf';

    // Constructor for upgradeable contracts. Initializes the base ERC2771 context.
    // @param forwarder The address of the trusted forwarder for meta-transactions.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder)
        ERC2771ContextUpgradeable(forwarder)
    {}

    // Initializes the contract. This function replaces the constructor for upgradeable contracts.
    // @param name The name of the NFT collection.
    // @param symbol The symbol of the NFT collection.
    // @param _descriptor The address of the Nouncillors descriptor contract.
    // @param _seeder The address of the Nouncillors seeder contract.
    function initialize(
        string memory name,
        string memory symbol,
        INouncillorsDescriptorMinimal _descriptor,
        INouncillorsSeeder _seeder
    ) public initializer {
        __ERC721_init(name, symbol);             // Initialize the ERC721 token with name and symbol.
        __ERC721Enumerable_init();               // Initialize the enumerable extension.
        __Ownable_init(msg.sender);              // Initialize the contract with the deployer as the owner.
        _transfersEnabled = false;               // Initially, transfers are disabled.
        descriptor = _descriptor;                // Set the descriptor contract.
        seeder = _seeder;                        // Set the seeder contract.
    }

    // Returns the contract's URI
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    // Allows the owner to set a new contract URI hash.
    // @param newContractURIHash The new hash to be set.
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    // Overrides the supportsInterface function.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Events...
    event NouncillorMinted(uint256 indexed tokenId, address indexed mintedBy);
    event WhitelistUpdated(bytes32 indexed newMerkleRoot);
    event TransferabilityToggled(bool transfersEnabled);

    // Errors...
    error NotWhitelisted();
    error AlreadyClaimed();
    error TransferDisabled();

    // Transferability...
    function toggleTransferability() public onlyOwner {
    _transfersEnabled = !_transfersEnabled;
    emit TransferabilityToggled(_transfersEnabled);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721Upgradeable, IERC721) {
    if (!_transfersEnabled) revert TransferDisabled();
    super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override (ERC721Upgradeable, IERC721) {
    if (!_transfersEnabled) revert TransferDisabled();
    super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override (ERC721Upgradeable, IERC721) {
    if (!_transfersEnabled) revert TransferDisabled();
    super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public override (ERC721Upgradeable, IERC721) {
    if (!_transfersEnabled) revert TransferDisabled();
    super.setApprovalForAll(operator, _approved);
    }

    // Whitelisting...
    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit WhitelistUpdated(_newMerkleRoot);
    }

    function isWhitelisted(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Meta-Transaction Overrides...
    /**
    * @dev Overrides the `_msgSender` function to support meta-transactions.
    * Meta-transactions allow a user to interact with the contract indirectly,
    * through a trusted forwarder. This helps users by allowing transactions
    * without needing ETH for gas, with the forwarder paying for it instead.
    * 
    * The function checks if the sender is the trusted forwarder and if the calldata
    * length is sufficient (at least 20 bytes, the size of an Ethereum address).
    * If both conditions are met, it interprets the sender as being the original
    * sender from the calldata, thus supporting meta-transactions.
    *
    * If the sender is not the trusted forwarder or the calldata length is insufficient,
    * it defaults to the original `msg.sender`.
    */
    function _msgSender() internal view virtual override (ERC2771ContextUpgradeable, ContextUpgradeable) returns (address sender) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            // Extracts the sender address from the end of the calldata. This is where
            // the sender's address is encoded in meta-transactions.
            // We use assembly for efficiency; `shr(96, calldataload(sub(calldatasize(), 20)))`
            // right-shifts the last 20 bytes of calldata (sender's address) to align it as an address.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            // If not a meta-transaction, just use the standard `msg.sender`.
            return super._msgSender();
        }
    }

    /**
    * @dev Overrides the `_msgData` function to support meta-transactions.
    * In the context of meta-transactions, the original transaction data
    * is sent along with the sender's address (last 20 bytes of calldata).
    * This function removes these last 20 bytes to obtain the original `msg.data`.
    *
    * If the sender is not the trusted forwarder or the calldata length is less
    * than 20 bytes, it defaults to the original `msg.data`.
    */
    function _msgData() internal view virtual override (ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            // Strips the last 20 bytes (sender's address) from the calldata to retrieve
            // the original transaction data.
            return msg.data[:msg.data.length - 20];
        } else {
            // If not a meta-transaction, just use the standard `msg.data`.
            return super._msgData();
        }
    }

    // Minting...
    function mint(bytes32[] calldata _merkleProof) public returns (uint256) {
        address sender = _msgSender();
        if (hasMinted[sender]) {
            revert AlreadyClaimed();
        }

        if (!isWhitelisted(sender, _merkleProof)) {
            revert NotWhitelisted();
        }

        hasMinted[sender] = true;
        uint256 newTokenId = _mintTo(sender, _currentNouncillorId++);
        emit NouncillorMinted(newTokenId, sender);
        return newTokenId;
    }

    function _mintTo(address to, uint256 nouncillorId) internal returns (uint256) {
        INouncillorsSeeder.Seed memory seed = seeds[nouncillorId] = seeder.generateSeed(nouncillorId, descriptor);

        _safeMint(to, nouncillorId);

        return nouncillorId;
    }
}

