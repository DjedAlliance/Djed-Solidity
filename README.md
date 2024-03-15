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