// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { NouncilDAOProxy } from "../contracts/governance/NouncilDAOProxy.sol";

contract AcceptAdminScript is Script {
    address public constant PROXY_ADDRESS = 0x8097173bCA40971642E3A780aAd420a45E8Cb610;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NouncilDAOProxy proxy = NouncilDAOProxy(PROXY_ADDRESS);

        // Call acceptAdminOnExecutor() to accept admin rights
        proxy.acceptAdminOnExecutor();

        console.log("Admin rights accepted by NouncilProxy.");

        vm.stopBroadcast();
    }
}
