# Djed

[![CI](https://github.com/DjedAlliance/Djed-Solidity/actions/workflows/CI.yml/badge.svg)](https://github.com/DjedAlliance/Djed-Solidity/actions/workflows/CI.yml)

Djed is a formally verified crypto-backed autonomous stablecoin protocol. To learn more, visit the [Djed Alliance's Website](http://www.djed.one).

## Setting Up

Install [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md). Then:

```
npm install
```

## Building and Testing

```
forge build
forge test
forge coverage
```

## Linting

Pre-configured `solhint` and `prettier-plugin-solidity`. Can be run by

```
npm run solhint
npm run prettier
```

## Deployments

The `scripts/env/` folder contain sample .env files for different networks. To deploy an instance of djed contract, create an .env file with and run:

 ```shell
forge script ./scripts/deployDjedContract.s.sol:DeployDjed -vvvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run(uint8)" -- <SupportedNetworks_ID> --verify
```

Refer `foundry.toml` for NETWORK_RPC_ENDPOINT and `scripts/Helper.sol` for SupportedNetworks_ID. Update `scripts/Helper.sol` file with each Oracle deployments.

To deploy chainlink oracle, run: 

 ```shell
forge script ./scripts/deployChainlinkOracle.s.sol:DeployChainlinkOracle -vvvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run()" --verify
```

We can also deploy Inverting Chainlink Oracle (if chainlink oracle returns price feed from ETH/USD, the corresponding inverting oracle would return price feed from USD/ETH), replace DeployChainlinkOracle with DeployInvertingChainlinkOracle in the above script. 