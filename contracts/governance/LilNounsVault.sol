// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

// Importing OpenZeppelin's modules
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { Votes } from "@openzeppelin/contracts/governance/utils/Votes.sol";

/**
 * @title LilNounsVault
 * @notice An upgradeable vault contract with pausable functionality for handling ETH, ERC20 tokens, and ERC721 NFTs.
 * @dev This contract uses the UUPS upgradeable pattern and inherits from OpenZeppelin's upgradeable contracts.
 * It allows the owner to pause operations, withdraw funds, and upgrade the contract implementation.
 */
contract LilNounsVault is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  IERC721Receiver
{
  using SafeERC20 for IERC20;

  /// @notice Thrown when an attempt is made to unpause during the restricted pause period.
  error EnforcedPausePeriod();

  /// @notice Thrown when the provided pause period is invalid.
  error InvalidPausePeriod();

  /// @notice Thrown when a zero address is provided where it's not allowed.
  error ZeroAddressError();

  /// @notice The timestamp when the pause period starts.
  uint256 public pauseStartTime;

  /// @notice The timestamp when the pause period ends.
  uint256 public pauseEndTime;

  /**
   * @notice Initializes the contract and sets the deployer as the initial owner.
   * @dev This function replaces the constructor in upgradeable contracts.
   */
  function initialize() public initializer {
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
  }

  /**
   * @notice Pauses the contract for a specific time period.
   * @dev Only the owner can call this function. The pause period is defined by start and end timestamps.
   * @param startTimestamp The timestamp when the pause period begins.
   * @param endTimestamp The timestamp when the pause period ends.
   */
  function pause(
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external onlyOwner {
    if (endTimestamp <= startTimestamp) {
      revert InvalidPausePeriod();
    }
    if (startTimestamp < block.timestamp) {
      revert InvalidPausePeriod();
    }

    pauseStartTime = startTimestamp;
    pauseEndTime = endTimestamp;
    _pause();
  }

  /**
   * @notice Unpauses the contract.
   * @dev Only the owner can call this function. It cannot be called during the restricted pause period.
   */
  function unpause() external onlyOwner {
    if (block.timestamp >= pauseStartTime && block.timestamp <= pauseEndTime) {
      revert EnforcedPausePeriod();
    }
    _unpause();
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * @dev Only the current owner can call this function. The contract must not be paused to transfer ownership.
   * @param newOwner The address of the new owner.
   */
  function transferOwnership(
    address newOwner
  ) public override onlyOwner whenNotPaused {
    if (newOwner == address(0)) {
      revert ZeroAddressError();
    }
    _transferOwnership(newOwner);
  }

  /**
   * @notice Authorizes an upgrade to a new implementation contract.
   * @dev This function ensures that upgrades can only be authorized by the owner and when the contract is not paused.
   * @param newImplementation The address of the new implementation contract.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal view override onlyOwner {
    if (
      paused() &&
      (block.timestamp >= pauseStartTime && block.timestamp <= pauseEndTime)
    ) {
      revert EnforcedPausePeriod();
    }

    // Suppress unused variable warning
    (newImplementation);
  }

  /**
   * @notice Withdraws all ETH from the contract to the owner's address.
   * @dev Only the owner can call this function. It is protected by non-reentrancy and can only be called when the contract is not paused.
   */
  function withdraw() external onlyOwner whenNotPaused nonReentrant {
    uint256 amount = address(this).balance;
    Address.sendValue(payable(owner()), amount);
  }

  /**
   * @notice Withdraws a specific ERC20 token from the contract to the owner's address.
   * @dev Only the owner can call this function. It is protected by non-reentrancy and can only be called when the contract is not paused.
   * @param token The address of the ERC20 token contract.
   */
  function withdraw(
    IERC20 token
  ) external onlyOwner whenNotPaused nonReentrant {
    uint256 balance = token.balanceOf(address(this));
    token.safeTransfer(owner(), balance);
  }

  /**
   * @notice Withdraws a specific ERC721 token from the contract to the owner's address.
   * @dev Only the owner can call this function. It is protected by non-reentrancy and can only be called when the contract is not paused.
   * @param nft The address of the ERC721 NFT contract.
   * @param tokenId The ID of the NFT to withdraw.
   */
  function withdraw(
    IERC721 nft,
    uint256 tokenId
  ) external onlyOwner whenNotPaused nonReentrant {
    nft.safeTransferFrom(address(this), owner(), tokenId);
  }

  /**
   * @notice Delegates the votes of a specific `Votes` token (ERC20Votes or ERC721Votes) to another address.
   * @dev Only the owner can call this function.
   * @param token The address of the Votes token contract.
   * @param delegatee The address to delegate the votes to.
   */
  function delegate(address token, address delegatee) external onlyOwner {
    if (delegatee == address(0)) {
      revert ZeroAddressError();
    }

    // Cast the token address to the Votes interface and delegate the votes
    Votes(token).delegate(delegatee);
  }

  /**
   * @notice Function to receive ETH deposits.
   * @dev This function allows the contract to accept ETH.
   */
  receive() external payable {}

  /**
   * @notice Handles the receipt of ERC721 NFTs.
   * @dev This function is called when an ERC721 token is transferred to this contract.
   * @return bytes4 The selector of the `onERC721Received` function.
   */
  function onERC721Received(
    address, // operator
    address, // from
    uint256, // tokenId
    bytes calldata // data
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}