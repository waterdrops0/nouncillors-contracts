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
event TransferabilityToggled(bool transfersEnabled);


/// @dev Errors
error NotWhitelisted();
error AlreadyClaimed();
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
    bool private _transfersEnabled;
    bytes32 private merkleRoot;

    function initialize(
        string memory name,
        string memory symbol,
        INounsDescriptorMinimal _descriptor,
        INounsSeeder _seeder
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        _transfersEnabled = false;
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    //Transferability...

    function toggleTransferability() public onlyOwner {
    _transfersEnabled = !_transfersEnabled;
    emit TransferabilityToggled(_transfersEnabled);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
    if (!transfersEnabled) revert TransferDisabled();
    super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    if (!transfersEnabled) revert TransferDisabled();
    super.safeTransferFrom(from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    if (!transfersEnabled) revert TransferDisabled();
    super.safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
    if (!transfersEnabled) revert TransferDisabled();
    super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public override {
    if (!transfersEnabled) revert TransferDisabled();
    super.setApprovalForAll(operator, _approved);
    }


    // Whitelisting...

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

        return nouncillorId;
    }


    
}

