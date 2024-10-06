// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

// Import contracts
import "../contracts/NouncillorsToken.sol";
import "../contracts/NouncillorsDescriptor.sol";
import "../contracts/NFTDescriptor.sol";
import "../contracts/NouncillorsArt.sol";
import "../contracts/Inflator.sol";
import "../contracts/SVGRenderer.sol";
import "../contracts/ERC2771Forwarder.sol";
import "../contracts/NouncilDAOProxy.sol";
import "../contracts/NouncilDAOLogic.sol";
import "../contracts/NouncilDAOExecutor.sol";

contract DeployNouncilProtocol is Script {
    function run() public {
        // Fetch the private key of the deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Begin deployment
        console2.log("Deploying contracts...");

        // Initialize variables
        string memory tokenName = "Nouncillors";
        string memory tokenSymbol = "NNN";

        // Deploy SVGRenderer
        SVGRenderer svgRenderer = new SVGRenderer();
        console2.log("SVGRenderer deployed to:", address(svgRenderer));

        // Deploy Inflator
        Inflator inflator = new Inflator();
        console2.log("Inflator deployed to:", address(inflator));

        // Deploy NFTDescriptor
        NFTDescriptor nftDescriptor = new NFTDescriptor();
        console2.log("NFTDescriptor deployed to:", address(nftDescriptor));

        // Deploy ERC2771Forwarder
        ERC2771Forwarder erc2771Forwarder = new ERC2771Forwarder("NouncilForwarder");
        console2.log("ERC2771Forwarder deployed to:", address(erc2771Forwarder));

        // Deploy NouncillorsArt
        // We set the descriptor address to zero initially and update it later
        NouncillorsArt nouncillorsArt = new NouncillorsArt(address(0), address(inflator));
        console2.log("NouncillorsArt deployed to:", address(nouncillorsArt));

        // Deploy NouncillorsDescriptor with linked NFTDescriptor library
        // You need to link the library manually during compilation
        NouncillorsDescriptor nouncillorsDescriptor = new NouncillorsDescriptor(
            msg.sender,
            address(nouncillorsArt),
            address(svgRenderer)
        );
        console2.log("NouncillorsDescriptor deployed to:", address(nouncillorsDescriptor));

        // Update the NouncillorsArt with the descriptor address
        nouncillorsArt.setDescriptor(address(nouncillorsDescriptor));

        // Deploy NouncillorsToken
        NouncillorsToken nouncillorsToken = new NouncillorsToken(
            msg.sender, // Owner
            tokenName,
            tokenSymbol,
            address(erc2771Forwarder),
            address(nouncillorsDescriptor)
        );
        console2.log("NouncillorsToken deployed to:", address(nouncillorsToken));

        // Deploy NouncilDAOExecutor
        address admin = msg.sender;
        uint256 delay = 2 days; // Example delay
        NouncilDAOExecutor daoExecutor = new NouncilDAOExecutor(admin, delay);
        console2.log("NouncilDAOExecutor deployed to:", address(daoExecutor));

        // Deploy NouncilDAOLogic (implementation contract)
        NouncilDAOLogic daoLogic = new NouncilDAOLogic();
        console2.log("NouncilDAOLogic deployed to:", address(daoLogic));

        // Deploy NouncilDAOProxy (proxy contract)
        NouncilDAOProxy daoProxy = new NouncilDAOProxy(
            address(daoExecutor),
            address(nouncillorsToken),
            admin,
            address(daoLogic),
            delay
        );
        console2.log("NouncilDAOProxy deployed to:", address(daoProxy));

        // Finish deployment
        vm.stopBroadcast();
        console2.log("Contracts deployed successfully!");
    }
}
