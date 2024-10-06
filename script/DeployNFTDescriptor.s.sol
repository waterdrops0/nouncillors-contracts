// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/libs/NFTDescriptor.sol";

contract DeployNFTDescriptor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTDescriptor nftDescriptor = new NFTDescriptor();
        console.log("NFTDescriptor deployed to:", address(nftDescriptor));

        vm.stopBroadcast();
    }
}

