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

contract NouncillorsToken is INouncillorsToken, ERC2771ContextUpgradeable, ERC721Upgradeable, OwnableUpgradeable {
    using MerkleProof for bytes32;

    // The descriptor contract that defines how Nouncillors NFTs should be displayed.
    INouncillorsDescriptorMinimal public descriptor;

    // The seeder contract that provides the randomness seed for NFTs.
    INouncillorsSeeder public seeder;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

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

   /**
    * @dev Ensures descriptor is unlocked; reverts if locked.
    */
    modifier whenDescriptorNotLocked() {
        if (isDescriptorLocked) {
            revert DescriptorLocked();
        }
        _;
    }

   /**
    * @dev Ensures seeder is unlocked; reverts if locked.
    */
    modifier whenSeederNotLocked() {
        if (isSeederLocked) {
            revert SeederLocked();
        }
        _;
    }

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
        __Ownable_init(msg.sender);              // Initialize the contract with the deployer as the owner.
        _transfersEnabled = false;               // Initially, transfers are disabled.
        descriptor = _descriptor;                // Set the descriptor contract.
        seeder = _seeder;                        // Set the seeder contract.
    }

   /**
    * @notice Retrieves the contract's URI.
    * @dev Constructs the full URI by appending the IPFS gateway prefix to the stored hash.
    * @return The full contract URI.
    */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

   /**
    * @notice Allows the owner to update the contract URI hash.
    * @dev Requires the caller to be the contract owner.
    * @param newContractURIHash The new hash to be set for the contract URI.
    */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

   /**
    * @notice Returns a distinct Uniform Resource Identifier (URI) for a given asset.
    * @dev Overrides IERC721Metadata's tokenURI function.
    * @param tokenId The token ID for which URI is requested.
    * @return The token URI of the given token ID.
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentTokenQuery(tokenId);
        }
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

   /**
    * @notice Returns a data URI for a given asset, base64 encoded with JSON contents inlined.
    * @dev Similar to `tokenURI`, but provides the data URI.
    * @param tokenId The token ID for which data URI is requested.
    * @return The data URI of the given token ID.
    */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentTokenQuery(tokenId);
        }
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

   /**
    * @notice Mints a new token if the sender is whitelisted and hasn't minted before.
    * @dev Utilizes a Merkle proof to verify if the sender is whitelisted. Reverts if the sender
    * has already minted a token or if they are not whitelisted.
    * @param _merkleProof The Merkle proof that proves the sender's address is in the whitelist.
    * @return The ID of the newly minted token.
    */
    function mint(bytes32[] calldata _merkleProof) external returns (uint256) {
        address sender = _msgSender();

        // Revert if the sender has already minted
        if (hasMinted[sender]) {
            revert AlreadyClaimed();
        }

        // Revert if the sender is not whitelisted
        if (!isWhitelisted(sender, _merkleProof)) {
            revert NotWhitelisted();
        }

        // Mark as minted and proceed to mint the token
        hasMinted[sender] = true;
        return _mintTo(sender, _currentNouncillorId++);
    }

   /**
    * @notice Sets a new Merkle root for whitelist verification.
    * @dev Can only be called by the contract owner. Emits a WhitelistUpdated event upon change.
    * @param _newMerkleRoot The new Merkle root to be set for whitelist verification.
    */
    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit WhitelistUpdated(_newMerkleRoot);
    }

   /**
    * @notice Checks if an address is whitelisted by verifying against the Merkle root.
    * @dev Verifies the provided Merkle proof against the stored Merkle root to determine whitelist status.
    * @param _address The address to check for whitelisting.
    * @param _merkleProof The Merkle proof demonstrating the address's inclusion in the whitelist.
    * @return True if the address is whitelisted, false otherwise.
    */
    function isWhitelisted(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

   /**
    * @notice Toggles the transferability of the tokens.
    * @dev Can only be called by the contract owner. Emits TransferabilityToggled event.
    */
    function toggleTransferability() public onlyOwner {
        _transfersEnabled = !_transfersEnabled;
        emit TransferabilityToggled(_transfersEnabled);
    }

    // Transfer a token (reverts if transfers are disabled).
    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721Upgradeable, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.transferFrom(from, to, tokenId);
    }

    // Safely transfer a token (reverts if transfers are disabled).
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override (ERC721Upgradeable, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // Approve a token transfer (reverts if transfers are disabled).
    function approve(address to, uint256 tokenId) public override (ERC721Upgradeable, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.approve(to, tokenId);
    }

    // Set approval for all tokens (reverts if transfers are disabled).
    function setApprovalForAll(address operator, bool _approved) public override (ERC721Upgradeable, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.setApprovalForAll(operator, _approved);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INouncillorsDescriptorMinimal _descriptor) external onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INouncillorsSeeder _seeder) external onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

   /**
    * @notice Internal function to mint a token to a specified address.
    * @dev Mints a token to the given address, assigns a seed, emits a NouncillorMinted event,
    * and returns the token ID.
    * @param to The address to mint the token to.
    * @param nouncillorId The ID of the token to be minted.
    * @return The ID of the minted token.
    */
    function _mintTo(address to, uint256 nouncillorId) internal returns (uint256) {
        // Generate a seed for the new token
        INouncillorsSeeder.Seed memory seed = seeds[nouncillorId] = seeder.generateSeed(nouncillorId, descriptor);

        // Mint the token
        _safeMint(to, nouncillorId);

        // Emit an event for the minting
        emit NouncillorMinted(nouncillorId, seed, to);

        return nouncillorId;
    }

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
}