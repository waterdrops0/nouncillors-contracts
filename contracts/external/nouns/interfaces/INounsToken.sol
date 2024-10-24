// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.20;

import { INounsDescriptorArt } from './INounsDescriptorArt.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface INounsToken {
    function descriptor() external returns (INounsDescriptorArt);

    function seeder() external returns (INounsSeeder);

    function transferFrom(address from, address to, uint256 nounId) external;
}