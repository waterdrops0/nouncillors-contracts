const ethers = require('ethers');
const promptjs = require('prompt');
const { deflateRawSync } = require('zlib');
const utils = ethers.utils;

promptjs.colors = false;
promptjs.message = '> ';
promptjs.delimiter = '';

async function getGasPriceWithPrompt(ethers) {
  const gasPrice = await ethers.provider.getGasPrice();
  const gasInGwei = Math.round(Number(ethers.utils.formatUnits(gasPrice, 'gwei')));

  promptjs.start();

  let result = await promptjs.get([
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

  return ethers.utils.parseUnits(result.gasPrice.toString(), 'gwei');
}

async function getDeploymentConfirmationWithPrompt() {
  const result = await promptjs.get([
    {
      properties: {
        confirm: {
          type: 'string',
          description: 'Type "DEPLOY" to confirm:',
        },
      },
    },
  ]);

  return result.confirm == 'DEPLOY';
}

async function printEstimatedCost(factory, gasPrice) {
  const deploymentGas = await factory.signer.estimateGas(
    factory.getDeployTransaction({ gasPrice }),
  );
  const deploymentCost = deploymentGas.mul(gasPrice);
  console.log(
    `Estimated cost to deploy NounsDAOLogicV2: ${utils.formatUnits(deploymentCost, 'ether')} ETH`,
  );
}

function dataToDescriptorInput(data) {
  const abiCoder = ethers.AbiCoder.defaultAbiCoder()
  const abiEncoded = abiCoder.encode(['bytes[]'], [data]);
  const encodedCompressed = `0x${deflateRawSync(
    Buffer.from(abiEncoded.substring(2), 'hex'),
  ).toString('hex')}`;

  const originalLength = abiEncoded.substring(2).length / 2;
  const itemCount = data.length;
  console.log("There are ", itemCount, "items.");

  return {
    encodedCompressed,
    originalLength,
    itemCount,
  };
}

function printContractsTable(contracts) {
  console.table(
    Object.values(contracts).reduce(
      (acc, contract) => {
        acc[contract.name] = {
          Address: contract.address,
        };
        if (contract.instance?.deployTransaction) {
          acc[contract.name]['Deployment Hash'] = contract.instance.deployTransaction.hash;
        }
        return acc;
      },
      {},
    ),
  );
}

module.exports = {
  getGasPriceWithPrompt,
  getDeploymentConfirmationWithPrompt,
  printEstimatedCost,
  dataToDescriptorInput,
  printContractsTable,
};
