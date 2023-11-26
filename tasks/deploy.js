const { task } = require('hardhat/config');
const ethers = require('ethers');
const promptjs = require('prompt');

// Configuration for the prompt used in interactive mode
promptjs.colors = false;
promptjs.message = '> ';
promptjs.delimiter = '';

// This offset is used to predict the address of the NouncillorsArt contract
const NOUNCILLORS_ART_NONCE_OFFSET = 4;

task('deploy', 'Deploys NFTDescriptor, SVGRenderer, Inflator, NouncillorsDescriptor, NouncillorsArt, NouncillorsSeeder, and NouncillorsToken')
  .addFlag('autoDeploy', 'Deploy all contracts without user interaction')
  .setAction(async (args, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    // Predicting the address of the NouncillorsArt contract
    const nonce = await deployer.getTransactionCount();
    const expectedNouncillorsArtAddress = hre.ethers.utils.getContractAddress({
      from: deployer.address,
      nonce: nonce + NOUNCILLORS_ART_NONCE_OFFSET,
    });

    const deployment = {};
    const contracts = {
      SVGRenderer: {},
      Inflator: {},
      NFTDescriptor: {},
      NouncillorsDescriptor: {
        args: [expectedNouncillorsArtAddress, () => deployment.SVGRenderer.address],
      },
      NouncillorsArt: {
        args: [() => deployment.NouncillorsDescriptor.address, () => deployment.Inflator.address],
      },
      NouncillorsSeeder: {},
      NouncillorsToken: {
        args: [
          'NouncillorsToken', // Token name
          'NCL', // Token symbol
          () => deployment.NouncillorsDescriptor.address,
          () => deployment.NouncillorsSeeder.address,
        ],
      },
    };

    // Looping through each contract for deployment
    for (const [name, contract] of Object.entries(contracts)) {
      let gasPrice = await hre.ethers.provider.getGasPrice();

      // If not auto-deploying, interactively set the gas price
      if (!args.autoDeploy) {
        const gasInGwei = Math.round(Number(hre.ethers.utils.formatUnits(gasPrice, 'gwei')));
        promptjs.start();
        const result = await promptjs.get([
          {
            properties: {
              gasPrice: {
                type: 'integer',
                required: true,
                description: 'Enter a gas price (gwei)',
                default: gasInGwei,
              },
            },
          },
        ]);
        gasPrice = hre.ethers.utils.parseUnits(result.gasPrice.toString(), 'gwei');
      }

      // Creating the contract factory
      const factory = await hre.ethers.getContractFactory(name);

      // Estimating gas for deployment
      const deploymentGas = await factory.signer.estimateGas(
        factory.getDeployTransaction(
          ...(contract.args?.map(a => (typeof a === 'function' ? a() : a)) ?? []),
          {
            gasPrice,
          },
        ),
      );
      const deploymentCost = deploymentGas.mul(gasPrice);

      // Displaying the estimated cost
      console.log(
        `Estimated cost to deploy ${name}: ${hre.ethers.utils.formatUnits(
          deploymentCost,
          'ether',
        )} ETH`,
      );

      // Interactive confirmation for deployment
      if (!args.autoDeploy) {
        const result = await promptjs.get([
          {
            properties: {
              confirm: {
                pattern: /^(DEPLOY|SKIP|EXIT)$/,
                description:
                  'Type "DEPLOY" to confirm, "SKIP" to skip this contract, or "EXIT" to exit.',
              },
            },
          },
        ]);
        if (result.confirm === 'SKIP') {
          console.log(`Skipping ${name} deployment...`);
          continue;
        }
        if (result.confirm === 'EXIT') {
          console.log('Exiting...');
          return;
        }
      }

      // Deploying the contract
      console.log(`Deploying ${name}...`);
      const deployedContract = await factory.deploy(
        ...(contract.args?.map(a => (typeof a === 'function' ? a() : a)) ?? []),
        {
          gasPrice,
        },
      );

      // Awaiting deployment confirmation
      await deployedContract.deployed();

      // Storing deployment information
      deployment[name] = {
        name,
        instance: deployedContract,
        address: deployedContract.address,
        constructorArguments: contract.args?.map(a => (typeof a === 'function' ? a() : a)) ?? [],
      };

      console.log(`${name} contract deployed to ${deployedContract.address}`);
    }

    // Returning all deployment information
    return deployment;
  });
