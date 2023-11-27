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
    INouncillorsDescriptorMinimal public descriptor;
    INouncillorsSeeder public seeder;
    mapping(uint256 => INouncillorsSeeder.Seed) public seeds;
    uint256 private _currentNouncillorId;
    mapping(address => bool) private hasMinted;
    bool private _transfersEnabled;
    bytes32 private merkleRoot;
    string private _contractURIHash = 'EjsnYhfWQdasdACASf';

    function initialize(
        string memory name,
        string memory symbol,
        ERC2771ForwarderUpgradeable forwarder,
        INouncillorsDescriptorMinimal _descriptor,
        INouncillorsSeeder _seeder
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC2771Context_init(address(forwarder));
        __Ownable_init(msg.sender);
        _transfersEnabled = false;
        descriptor = _descriptor;
        seeder = _seeder;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
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

    function transferFrom(address from, address to, uint256 tokenId) public override {
    if (!_transfersEnabled) revert TransferDisabled();
    super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    if (!_transfersEnabled) revert TransferDisabled();
    super.safeTransferFrom(from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    if (!_transfersEnabled) revert TransferDisabled();
    super.safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
    if (!_transfersEnabled) revert TransferDisabled();
    super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public override {
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


    // Minting...

    function mint(bytes32[] calldata _merkleProof) public returns (uint256) {
        address sender = _msg.sender();
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

