const { task } = require('hardhat/config');
const { printContractsTable } = require('./utils');

task('deploy-and-configure', 'Deploy and configure all contracts')
  .addFlag('autoDeploy', 'Deploy all contracts without user interaction')
  .setAction(async (args, hre) => {
    // Deploy the Nouns DAO contracts and return deployment information
    const contracts = await hre.run('deploy', args);

    // Verify the contracts on Etherscan
    await hre.run('verify-etherscan', {
      contracts,
    });

    // Populate the on-chain art
    await hre.run('populate-descriptor', {
      nftDescriptor: contracts.NFTDescriptorV2.address,
      nounsDescriptor: contracts.NounsDescriptorV2.address,
    });

    printContractsTable(contracts);
    console.log('Deployment Complete.');
  });
