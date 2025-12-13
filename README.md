# Djed

[![CI](https://github.com/DjedAlliance/Djed-Solidity/actions/workflows/CI.yml/badge.svg)](https://github.com/DjedAlliance/Djed-Solidity/actions/workflows/CI.yml)

Djed is a formally verified crypto-backed autonomous stablecoin protocol. To learn more, visit the [Djed Alliance's Website](http://www.djed.one).

## Protocol Variants

This repository contains three variants of the Djed stablecoin protocol:

### 1. **Djed** (Standard)
The original implementation with:
- Single oracle price feed
- Reserve ratio constraints (min/max)
- Linear treasury fee decay
- `sellBothCoins()` function for atomic operations

### 2. **Djed Shu**
Enhanced version with:
- Dual-oracle pricing (24-hour min/max)
- Reserve ratio constraints (min/max)
- Linear treasury fee decay
- Protection against flash-crash attacks
- `sellBothCoins()` function

### 3. **Djed Tefnut** (New)
Simplified variant based on Djed Shu with:
- ✅ Dual-oracle pricing (24-hour min/max)
- ❌ No reserve ratio constraints (maximum flexibility)
- ❌ No `sellBothCoins()` function (simplified)
- ❌ Fixed treasury fee (no linear decay)
- **Use cases**: Experimental deployments, testing, volatile markets
- **Trade-off**: Higher risk, requires active monitoring

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

### Run Specific Test Suites

Test individual protocol variants:

```bash
# Test standard Djed
forge test --match-contract DjedTest -vv

# Test Djed Shu
forge test --match-contract DjedShuTest -vv

# Test Djed Tefnut
forge test --match-contract DjedTefnutTest -vv
```

### Tefnut Test Coverage

The Tefnut implementation includes 17 comprehensive tests covering:
- ✅ No reserve ratio constraints on all operations
- ✅ Removal of `sellBothCoins()` function
- ✅ Fixed treasury fee (no decay mechanism)
- ✅ Dual-oracle pricing (min/max from 24h window)
- ✅ Core mint/redeem flows for SC and RC
- ✅ Fee distribution (treasury, protocol, UI)
- ✅ Multi-user transaction scenarios

## Linting

Pre-configured `solhint` and `prettier-plugin-solidity`. Can be run by

```
npm run solhint
npm run prettier
```

## Deployments

The `scripts/env/` folder contain sample .env files for different networks. 

### Deploy Djed (Standard)

To deploy an instance of the standard Djed contract:

 ```shell
forge script ./scripts/deployDjedContract.s.sol:DeployDjed -vvvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run(uint8)" -- <SupportedNetworks_ID> --verify
```

### Deploy Djed Shu

To deploy the Shu variant with dual-oracle pricing:

 ```shell
forge script ./scripts/deployDjedShuContract.sol:DeployDjedShu -vvvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run(uint8)" -- <SupportedNetworks_ID> --verify
```

### Deploy Djed Tefnut

To deploy the simplified Tefnut variant:

 ```shell
forge script ./scripts/deployDjedTefnutContract.s.sol:DeployDjedTefnutContract --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --verify
```

**Note**: Update the network in the deployment script before running. Tefnut uses the same oracle infrastructure as Shu.

Refer `foundry.toml` for NETWORK_RPC_ENDPOINT and `scripts/DeploymentParameters.sol` for SupportedNetworks_ID. Update `scripts/DeploymentParameters.sol` file with each Oracle deployments.

### Deploy Oracles

To deploy chainlink oracle, run: 

 ```shell
forge script ./scripts/deployChainlinkOracle.s.sol:DeployChainlinkOracle -vvvv --broadcast --rpc-url <NETWORK_RPC_ENDPOINT> --sig "run()" --verify
```

We can also deploy Inverting Chainlink Oracle (if chainlink oracle returns price feed from ETH/USD, the corresponding inverting oracle would return price feed from USD/ETH), replace DeployChainlinkOracle with DeployInvertingChainlinkOracle in the above script.

## Protocol Comparison

| Feature | Djed | Djed Shu | Djed Tefnut |
|---------|------|----------|-------------|
| **Oracle Type** | Single price | Dual (24h min/max) | Dual (24h min/max) |
| **Reserve Ratio Min** | ✅ Enforced | ✅ Enforced | ❌ No constraint |
| **Reserve Ratio Max** | ✅ Enforced | ✅ Enforced | ❌ No constraint |
| **Treasury Fee** | 📉 Linear decay | 📉 Linear decay | 📊 Fixed |
| **sellBothCoins()** | ✅ Available | ✅ Available | ❌ Removed |
| **Flash-crash Protection** | ❌ No | ✅ Yes | ✅ Yes |
| **Complexity** | Medium | High | Low |
| **Security** | Medium | High | Medium |
| **Flexibility** | Medium | Low | High |
| **Gas Cost** | Medium | High | Low |
| **Best For** | General use | Production | Testing/Experimental |

## Contract Architecture

```
src/
├── Djed.sol                      # Standard implementation
├── DjedShu.sol                   # Time-weighted oracle variant
├── DjedTefnut.sol                # Simplified variant (NEW)
├── Coin.sol                      # ERC20 for SC and RC
├── IOracle.sol                   # Standard oracle interface
├── IOracleShu.sol                # Dual-oracle interface
├── ShuOracleConverter.sol        # Wraps oracle with 24h tracking
├── ChainlinkOracle.sol           # Chainlink integration
├── ChainlinkInvertingOracle.sol  # Inverted Chainlink feed
├── API3Oracle.sol                # API3 integration
├── API3InvertingOracle.sol       # Inverted API3 feed
├── HebeSwapOracle.sol            # DEX-based pricing
├── HebeSwapInvertingOracle.sol   # Inverted DEX pricing
└── mock/
    ├── MockOracle.sol            # Testing oracle
    └── MockShuOracle.sol         # Testing dual oracle (UPDATED)
```

## Key Differences: Djed Tefnut

Tefnut is designed for maximum flexibility by removing safety constraints:

**Removed:**
- `reserveRatioMin` and `reserveRatioMax` - No overcollateralization requirements
- `sellBothCoins()` - Simplified selling mechanism
- `treasuryRevenue` and `treasuryRevenueTarget` - No fee decay tracking
- `isRatioAboveMin()` and `isRatioBelowMax()` - No ratio validation

**Preserved:**
- Dual-oracle pricing from DjedShu for flash-crash protection
- All core mint/redeem functionality
- Fee distribution (treasury, protocol, UI)
- Transaction limits and threshold supply checks
- Reentrancy protection

**Use Cases:**
- Experimental deployments on new chains
- Testing different economic parameters
- Markets with high volatility
- Scenarios where ratio constraints are too restrictive

**⚠️ Warning:** Tefnut has no overcollateralization guarantees. It can operate with reserve < liabilities. Suitable for testing and experimental use only.

## Contributing

Contributions are welcome! Please ensure:
1. All tests pass: `forge test`
2. Code is formatted: `npm run prettier`
3. No linting errors: `npm run solhint`
4. New features include comprehensive tests

## License

See [LICENSE.md](LICENSE.md) for details. 