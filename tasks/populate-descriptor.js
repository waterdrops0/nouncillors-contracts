const { task } = require('hardhat/config');
const ImageData = require('../files/image-data-v2.json');
const { dataToDescriptorInput } = require('./utils');

task('populate-descriptor', 'Populates the descriptor with color palettes and Nouncillor parts')
  .addOptionalParam(
    'nftDescriptor',
    'The `NFTDescriptor` contract address',
    '0x154f7604790ADF3DE783e7202f814BB0A73972Ec',
  )
  .addOptionalParam(
    'nouncillorsDescriptor',
    'The `NouncillorsDescriptor` contract address',
    '0x682401c50dee3DDB42b23696a2f20817148A6b0a',
  )
  .setAction(async ({ nftDescriptor, nouncillorsDescriptor }, hre) => {
    const options = { gasLimit: hre.network.name === 'hardhat' ? 30000000 : undefined };

    const descriptorFactory = await hre.ethers.getContractFactory('NouncillorsDescriptor', {
      libraries: {
        NFTDescriptor: nftDescriptor,
      },
    });
    const descriptorContract = descriptorFactory.attach(nouncillorsDescriptor);

    const { bgcolors, palette, images } = ImageData;
    const { bodies, accessories, heads, glasses } = images;

    const bodyData = bodies.map(({ data }) => data);
    console.log(bodyData);

    const bodiesPage = dataToDescriptorInput(bodies.map(({ data }) => data));
    const headsPage = dataToDescriptorInput(heads.map(({ data }) => data));
    const glassesPage = dataToDescriptorInput(glasses.map(({ data }) => data));
    const accessoriesPage = dataToDescriptorInput(accessories.map(({ data }) => data));

    await descriptorContract.addManyBackgrounds(bgcolors);
    await descriptorContract.setPalette(0, `0x000000${palette.join('')}`);

    await descriptorContract.addBodies(
      bodiesPage.encodedCompressed,
      bodiesPage.originalLength,
      bodiesPage.itemCount,
      options,
    );
    await descriptorContract.addHeads(
      headsPage.encodedCompressed,
      headsPage.originalLength,
      headsPage.itemCount,
      options,
    );
    await descriptorContract.addGlasses(
      glassesPage.encodedCompressed,
      glassesPage.originalLength,
      glassesPage.itemCount,
      options,
    );
    await descriptorContract.addAccessories(
      accessoriesPage.encodedCompressed,
      accessoriesPage.originalLength,
      accessoriesPage.itemCount,
      options,
    );

    console.log('Descriptor populated with palettes and parts.');
  });