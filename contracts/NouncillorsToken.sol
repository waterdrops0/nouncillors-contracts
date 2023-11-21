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

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/INouncillorsDescriptorMinimal.sol";
import "./interfaces/INouncillorsSeeder.sol";
import './interfaces/INouncillorsToken.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



/// @dev Events
event WhitelistUpdated(uint256 indexed templateId, string name, string description, string image);
event NouncillorMinted(uint256 indexed tokenId, uint256 indexed templateId);

/// @dev Errors
error OnlyAdmin();
error NotWhitelisted();
error AlreadyClaimed();
error InvalidTokenId();
error TransferDisabled();


contract NouncillorsToken is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using MerkleProof for bytes32;
    address public minter;
    INounsDescriptorMinimal public descriptor;
    INounsSeeder public seeder;
    bool public isMinterLocked;
    bool public isDescriptorLocked;
    bool public isSeederLocked;
    mapping(uint256 => INouncillorsSeeder.Seed) public seeds;
    uint256 private _currentNouncillorId;
    string private _contractURIHash = 'EjsnYhfWQdasdACASf';
    bytes32 private merkleRoot;


    // Custom modifiers
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "Descriptor is locked");
        _;
    }

    modifier whenSeederNotLocked() {
        require(!isSeederLocked, "Seeder is locked");
        _;
    }


    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _minter,
        INounsDescriptorMinimal _descriptor,
        INounsSeeder _seeder
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
    }

    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }


    // When using ERC721EnumerableUpgradeable, you need to override a few functions to integrate the enumerable functionality correctly.

      function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    merkleRoot = _newMerkleRoot;
    }

    function isWhitelisted(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }



// Minting...

    function mint(bytes32[] calldata _merkleProof) public returns (uint256) {
        if (!isWhitelisted(msg.sender, _merkleProof)) {
            revert NotWhitelisted();
        }
        return _mintTo(minter, _currentNouncillorId++);
    }

    function _mintTo(address to, uint256 nouncillorId) internal returns (uint256) {
        INouncillorsSeeder.Seed memory seed = seeds[nouncillorId] = seeder.generateSeed(nouncillorId, descriptor);

        _safeMint(to, nouncillorId);

        return nouncillortId;
    }


    
}

