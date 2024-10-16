// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { NouncillorsDescriptor } from '../../../contracts/NouncillorsDescriptor.sol';
import { SVGRenderer } from '../../../contracts/SVGRenderer.sol';
import { NouncillorsArt } from '../../../contracts/NouncillorsArt.sol';
import { Inflator } from '../../../contracts/Inflator.sol';
import { Constants } from './Constants.sol';
import { strings } from '../lib/strings.sol';

abstract contract DescriptorHelpers is Test, Constants {
    using strings for string;
    using strings for strings.slice;

    function _deployDescriptor() internal returns (NouncillorsDescriptor) {
        SVGRenderer renderer = new SVGRenderer();
        Inflator inflator = new Inflator();

        // Step 1: Deploy descriptor with a placeholder art address
        NouncillorsDescriptor descriptor = new NouncillorsDescriptor(address(this), NouncillorsArt(address(0)), renderer);

        // Step 2: Deploy art with the descriptor's address
        NouncillorsArt art = new NouncillorsArt(address(descriptor), inflator);

        // Step 3: Update the descriptor with the correct art address
        descriptor.setArt(art);

        return descriptor;
    }
    
    function _populateDescriptor(NouncillorsDescriptor descriptor) internal {
        // created with `npx hardhat descriptor-art-to-console`
        (bytes memory palette, string[] memory backgrounds) = abi.decode(
            readFile('./test/foundry/files/descriptor_v2/paletteAndBackgrounds.abi'),
            (bytes, string[])
        );
        descriptor.setPalette(0, palette);
        descriptor.addManyBackgrounds(backgrounds);

        (bytes memory bodies, uint80 bodiesLength, uint16 bodiesCount) = abi.decode(
            readFile('./test/foundry/files/descriptor_v2/bodiesPage.abi'),
            (bytes, uint80, uint16)
        );
        descriptor.addBodies(bodies, bodiesLength, bodiesCount);

        (bytes memory heads, uint80 headsLength, uint16 headsCount) = abi.decode(
            readFile('./test/foundry/files/descriptor_v2/headsPage.abi'),
            (bytes, uint80, uint16)
        );
        descriptor.addHeads(heads, headsLength, headsCount);

        (bytes memory accessories, uint80 accessoriesLength, uint16 accessoriesCount) = abi.decode(
            readFile('./test/foundry/files/descriptor_v2/accessoriesPage.abi'),
            (bytes, uint80, uint16)
        );
        descriptor.addAccessories(accessories, accessoriesLength, accessoriesCount);

        (bytes memory glasses, uint80 glassesLength, uint16 glassesCount) = abi.decode(
            readFile('./test/foundry/files/descriptor_v2/glassesPage.abi'),
            (bytes, uint80, uint16)
        );
        descriptor.addGlasses(glasses, glassesLength, glassesCount);
    }

    function readFile(string memory filepath) internal returns (bytes memory output) {
        string[] memory inputs = new string[](2);
        inputs[0] = 'cat';
        inputs[1] = filepath;
        output = vm.ffi(inputs);
    }

    function getGlassesPage()
        public
        returns (
            bytes memory glasses,
            uint80 glassesLength,
            uint16 glassesCount
        )
    {
        return abi.decode(readFile('./test/foundry/files/descriptor_v2/glassesPage.abi'), (bytes, uint80, uint16));
    }

    function removeDataTypePrefix(string memory str) internal pure returns (string memory) {
        // remove data type prefix like `data:application/json;base64,`

        strings.slice memory strSlice = str.toSlice();
        // modifies the slice to start after the prefix
        strSlice.split(string(',').toSlice());
        return strSlice.toString();
    }
}
