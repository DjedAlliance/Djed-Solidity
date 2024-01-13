The `scripts/env/` folder contain sample `.env` files for the deployment scripts in the `scripts/` folder.

For example, the file `scripts/env/deployDjedContract/milkomeda.env` contain the parameters that were used to deploy Milkomeda Djed Osiris on the Milkomeda blockchain.

To run a deployment script, create an `.env` file with the help of `scripts/env/deployDjedContract/empty.env` and run the following --
 ```shell
forge script ./scripts/deployDjedContract.s.sol:DeployDjed -vvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run(uint8)" -- <SupportedNetworks_ID>
```

Refer `foundry.toml` for NETWORK_RPC_ENDPOINT and `scripts/Helper.sol` for SupportedNetworks_ID