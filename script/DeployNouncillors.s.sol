// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

// Import contracts
import "../contracts/NouncillorsToken.sol";
import "../contracts/NouncillorsDescriptor.sol";
import "../contracts/NouncillorsArt.sol";
import "../contracts/Inflator.sol";
import "../contracts/SVGRenderer.sol";
import '@openzeppelin/contracts/metatx/ERC2771Forwarder.sol';
import "../contracts/governance/NouncilDAOProxy.sol";
import "../contracts/governance/NouncilDAOLogic.sol";
import "../contracts/governance/NouncilDAOExecutor.sol";

contract DeployNouncilProtocol is Script {
    function run() public {
        // Fetch the private key of the deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Initialize variables
        string memory tokenName = "Nouncillors";
        string memory tokenSymbol = "NNN";

        // Begin deployment process
        console2.log("Deploying contracts...");

        // Deploy SVGRenderer (which implements ISVGRenderer)
        SVGRenderer svgRenderer = new SVGRenderer();
        console2.log("SVGRenderer deployed to:", address(svgRenderer));

        // Deploy Inflator (which implements IInflator)
        Inflator inflator = new Inflator();
        console2.log("Inflator deployed to:", address(inflator));

        // Deploy ERC2771Forwarder
        ERC2771Forwarder erc2771Forwarder = new ERC2771Forwarder("NouncilForwarder");
        console2.log("ERC2771Forwarder deployed to:", address(erc2771Forwarder));

        // Calculate expected address for NouncillorsArt contract
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.timestamp)); // Generate a unique salt
        address expectedNouncillorsArtAddress = address(
            uint160(uint256(keccak256(
                abi.encodePacked(
                    bytes1(0xff), // 0xff is the "CREATE2" prefix byte
                    address(this), // The contract address deploying
                    salt,          // Salt for the deterministic address
                    keccak256(type(NouncillorsArt).creationCode) // Bytecode hash of NouncillorsArt
                )
            )))
        );
        console2.log("Expected NouncillorsArt address:", expectedNouncillorsArtAddress);

        // Deploy NouncillorsDescriptor using SVGRenderer and expected NouncillorsArt address
        NouncillorsDescriptor nouncillorsDescriptor = new NouncillorsDescriptor(
            msg.sender,
            INouncillorsArt(expectedNouncillorsArtAddress), // This expects a contract instance of INouncillorsArt
            ISVGRenderer(address(svgRenderer)) // Pass the SVGRenderer contract instance (cast as ISVGRenderer)
        );
        console2.log("NouncillorsDescriptor deployed to:", address(nouncillorsDescriptor));

        // Deploy NouncillorsArt using the NouncillorsDescriptor and Inflator (pass the contract instance, not address)
        NouncillorsArt nouncillorsArt = new NouncillorsArt(
            address(nouncillorsDescriptor),
            IInflator(address(inflator)) // Pass the Inflator contract instance (cast as IInflator)
        );
        console2.log("NouncillorsArt deployed to:", address(nouncillorsArt));

        // Deploy NouncillorsToken
        NouncillorsToken nouncillorsToken = new NouncillorsToken(
            msg.sender, // Owner
            tokenName,
            tokenSymbol,
            address(erc2771Forwarder),
            INouncillorsDescriptor(address(nouncillorsDescriptor))
        );
        console2.log("NouncillorsToken deployed to:", address(nouncillorsToken));

        // Finish deployment
        vm.stopBroadcast();
        console2.log("Contracts deployed successfully!");
    }
}
