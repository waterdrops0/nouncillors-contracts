![Nouncil Logo](https://github.com/curelycue/nouncillors-contracts/assets/22319741/13c335b7-47a2-4b9a-9fa3-a5dabbc08cc6)

## Smart Contract Overview

Nouncil Protocol is comprised of two primary components: Nouncillors and the DAO.

## Contracts

| Name                        | Address                                    | Sepoliascan                                                                                     |
|-----------------------------|--------------------------------------------|-------------------------------------------------------------------------------------------------|
| NouncillorsToken.sol        | 0x95745bB31eEb8278967f5E450dc8B31D34b02733 | https://sepolia.etherscan.io/address/0x95745bB31eEb8278967f5E450dc8B31D34b02733                  |
| NouncillorsDescriptor.sol   |                                            |                                                                                                 |
| NFTDescriptor.sol           |                                            |                                                                                                 |
| NouncillorsArt.sol          |                                            |                                                                                                 |
| Inflator.sol                |                                            |                                                                                                 |
| SVGRenderer.sol             |                                            |                                                                                                 |
| ERC2771Forwarder.sol        |                                            |                                                                                                 |
| NouncilDAOProxy.sol         |                                            |                                                                                                 |
| NouncilDAOLogic.sol         |                                            |                                                                                                 |
| NouncilDAOExecutor.sol      |                                            |                                                                                                 |

## Main Features

- Gasless Minting
- Onchain Art
- Dynamic Whitelisting
- Non-Transferability

## Feel absolutely free to:

- Fork the Repository
- Submit Pull Requests
- Open Issues for Discussion

### Contributions and Suggestions

Any contribution is welcome and greatly appreciated. ⌐◨-◨

### Build
To build the project, run:
```shell
forge build
```

### Test
To run tests, use:
```shell
forge test
```

### Deploy
1. Deploy the NFTDescriptor library and note its deployed address.
2. Update `foundry.toml` in the `[libraries]` section with the NFTDescriptor address to properly link it.
3. Re-compile your contracts to ensure correct linking.
4. Deploy the NouncillorsDescriptor contract and other contracts:

```shell
forge script script/DeployNFTDescriptor.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

Make sure to replace `<your_rpc_url>` and `<your_private_key>` with your actual RPC URL and private key values.