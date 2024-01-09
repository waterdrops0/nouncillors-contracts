const ethers = require('ethers');
const { deflateRawSync } = require('zlib');

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


module.exports = {
  dataToDescriptorInput
};
