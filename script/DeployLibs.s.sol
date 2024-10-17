// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NFTDescriptor} from "../contracts/libs/NFTDescriptor.sol"; 

contract DeployLibs is Script {
    function run() external {
        // Start broadcasting
        vm.startBroadcast();

        // Deploy the NFTDescriptor library
        NFTDescriptor nftDescriptor = new NFTDescriptor();
        console.log("NFTDescriptor deployed at:", address(nftDescriptor));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
