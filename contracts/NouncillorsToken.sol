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


import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./base/ERC721Checkpointable.sol";
import "./interfaces/INouncillorsDescriptorMinimal.sol";
import './interfaces/INouncillorsToken.sol';

contract NouncillorsToken is INouncillorsToken, Ownable, ERC721Checkpointable, ERC2771Context {
    using MerkleProof for bytes32;

    // The Nouncillors token URI descriptor
    INouncillorsDescriptorMinimal public descriptor;

    // The Nouncillors token seeder
    INounsSeeder public seeder;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;


    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Mapping from token ID to its corresponding seed.
    mapping(uint256 => Seed) public seeds;

    // Counter for the current token ID.
    uint256 private _currentNouncillorId;

    // Tracks whether an address has minted a token to enforce any minting restrictions.
    mapping(address => bool) private hasMinted;

    // Flag to control whether transfers are enabled or not.
    bool private _transfersEnabled;

    // Merkle root for verifying the whitelist.
    bytes32 private merkleRoot;

    // URI hash part of the contract metadata.
    string private _contractURIHash;

   /**
    * @notice Ensures descriptor has not been locked.
    */
    modifier whenDescriptorNotLocked() {
        if (isDescriptorLocked) {
            revert DescriptorisLocked();
        }
        _;
    }

   /**
    * @notice Ensures seeder has not been locked.
    */
    modifier whenSeederNotLocked() {
        if (isSeederLocked) {
            revert SeederisLocked();
        } 
        _;
    }

   /**
    * @dev Constructor for the NouncillorsToken contract.
    * @param name The name of the NFT collection.
    * @param symbol The symbol of the NFT collection.
    * @param _descriptor The address of the Nouncillors descriptor contract.
    * @param forwarder The address of the trusted forwarder for meta-transactions.
    */
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        ERC2771Forwarder forwarder,
        INouncillorsDescriptorMinimal _descriptor
       
    ) 
        ERC721(name, symbol) 
        Ownable(initialOwner)
        ERC2771Context(address(forwarder)) 
    {
        _transfersEnabled = false; // Initially, transfers are disabled.
        descriptor = _descriptor; // Set the descriptor contract.
        isDescriptorLocked = false; // Descriptor is initially unlocked.
        _currentNouncillorId = 0; // Start token ID counter at 0.
        _contractURIHash = 'EjsnYhfWQdasdACASf'; // Set URI hash.
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
        _requireOwned(tokenId);
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

   /**
    * @notice Returns a data URI for a given asset, base64 encoded with JSON contents inlined.
    * @dev Similar to `tokenURI`, but provides the data URI.
    * @param tokenId The token ID for which data URI is requested.
    * @return The data URI of the given token ID.
    */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }


    /**
     * @notice Mints a new token if the sender is whitelisted and hasn't minted before.
     * @dev Utilizes a Merkle proof to verify if the sender is whitelisted. Reverts if the sender
     * has already minted a token or if they are not whitelisted.
     * @param _merkleProof The Merkle proof that proves the sender's address is in the whitelist.
     * @param _seed The seed data to be associated with the minted Nouncillor NFT.
     * @return The ID of the newly minted token.
     */
    function mint(bytes32[] calldata _merkleProof, Seed calldata _seed) external returns (uint256) {
        address sender = _msgSender();

        // Revert if the sender has already minted
        if (hasMinted[sender]) {
            revert AlreadyClaimed();
        }

        // Revert if the sender is not whitelisted
        if (!isWhitelisted(sender, _merkleProof)) {
            revert NotWhitelisted();
        }

        // Validate seed values against the descriptor counts
        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();

        if (_seed.background >= backgroundCount) {
        revert InvalidSeedTrait("background", _seed.background, backgroundCount);
        }
        if (_seed.body >= bodyCount) {
            revert InvalidSeedTrait("body", _seed.body, bodyCount);
        }
        if (_seed.accessory >= accessoryCount) {
            revert InvalidSeedTrait("accessory", _seed.accessory, accessoryCount);
        }
        if (_seed.head >= headCount) {
            revert InvalidSeedTrait("head", _seed.head, headCount);
        }
        if (_seed.glasses >= glassesCount) {
            revert InvalidSeedTrait("glasses", _seed.glasses, glassesCount);
        }

        // Mark as minted and proceed to mint the token
        hasMinted[sender] = true;
        return _mintTo(sender, _currentNouncillorId++, _seed);
    }

   /**
     * @notice Burn a nouncillor.
     */
    function burn(uint256 nounId) public override onlyOwner {
        _burn(nouncillorId);
        emit NouncillorBurned(nouncillorId);
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
    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.transferFrom(from, to, tokenId);
    }

    // Safely transfer a token (reverts if transfers are disabled).
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override (ERC721, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // Approve a token transfer (reverts if transfers are disabled).
    function approve(address to, uint256 tokenId) public override (ERC721, IERC721) {
        if (!_transfersEnabled) revert TransferDisabled();
        super.approve(to, tokenId);
    }

    // Set approval for all tokens (reverts if transfers are disabled).
    function setApprovalForAll(address operator, bool _approved) public override (ERC721, IERC721) {
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
    function setSeeder(INouncillorsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

   /**
     * @notice Internal function to mint a token to a specified address.
     * @dev Mints a token to the given address, uses the provided seed, emits a NouncillorMinted event,
     * and returns the token ID.
     * @param to The address to mint the token to.
     * @param nouncillorId The ID of the token to be minted.
     * @param seed The seed data to be associated with the minted Nouncillor NFT.
     * @return The ID of the minted token.
     */
    function _mintTo(address to, uint256 nouncillorId, Seed calldata seed) internal returns (uint256) {
        // Use the provided seed for the new token
        seeds[nouncillorId] = seed;

        // Mint the token
        _safeMint(to, nouncillorId);

        // Emit an event for the minting
        emit NouncillorCreated(nouncillorId, seed, to);

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
    function _msgSender() internal view virtual override (ERC2771Context, Context) returns (address sender) {
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
    function _msgData() internal view virtual override (ERC2771Context, Context) returns (bytes calldata) {
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