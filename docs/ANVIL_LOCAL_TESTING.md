# Djed Local Testing Guide (Foundry + Anvil)

This guide is for running the Djed protocol locally on Anvil (`chainId=31337`) with minimal cost and fast iteration.

## 1. Start Anvil

Run Anvil in a separate terminal:

```bash
anvil
```

Use:
- RPC URL: `http://127.0.0.1:8545`
- Anvil account private key (example account #0):
  `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

## 2. Build the project

```bash
npm install
forge build
```

## 3. Export env vars (Git Bash)

```bash
export RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 4. Deploy MockOracle (real deployment, not dry run)

```bash
forge create src/mock/MockOracle.sol:MockOracle \
  --legacy \
  --broadcast \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --constructor-args 10000000000000000000
```

Copy the deployed MockOracle address from output.

## 5. Set oracle address in deployment params

Set `CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS` in
`scripts/DeploymentParameters.sol` to your deployed local `MockOracle` address.

## 6. Deploy Djed on Anvil

```bash
forge script scripts/deployDjedContract.s.sol:DeployDjed \
  --rpc-url "$RPC_URL" \
  --broadcast \
  -vvvv \
  --sig "run(uint8,uint8)" 0 0
```

Notes:
- `0 0` maps to `(SupportedNetworks.ETHEREUM_SEPOLIA, SupportedVersion.DJED)`.
- Current script signature expects two args: `run(uint8,uint8)`.

## 7. Verify Djed and discover token addresses

Replace `<DJED_ADDRESS>` from deployment output:

```bash
cast call <DJED_ADDRESS> "oracle()(address)" --rpc-url "$RPC_URL"
cast call <DJED_ADDRESS> "stableCoin()(address)" --rpc-url "$RPC_URL"
cast call <DJED_ADDRESS> "reserveCoin()(address)" --rpc-url "$RPC_URL"
```

Save:
- `SC_ADDRESS = stableCoin()`
- `RC_ADDRESS = reserveCoin()`

## 8. Check balances (on SC/RC, not Djed)

Replace `<USER_ADDRESS>`, `<SC_ADDRESS>`, `<RC_ADDRESS>`:

```bash
cast call <SC_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS> --rpc-url "$RPC_URL"
cast call <RC_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS> --rpc-url "$RPC_URL"
```

## 9. Bootstrap reserve by buying RC first

Replace placeholders:

```bash
cast send <DJED_ADDRESS> \
  "buyReserveCoins(address,uint256,address)" \
  <USER_ADDRESS> 0 0x0000000000000000000000000000000000000000 \
  --value 1ether \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

## 10. Buy SC

Start small:

```bash
cast send <DJED_ADDRESS> \
  "buyStableCoins(address,uint256,address)" \
  <USER_ADDRESS> 0 0x0000000000000000000000000000000000000000 \
  --value 0.01ether \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

## 11. Validate ratio and minted SC

```bash
cast call <DJED_ADDRESS> "ratio()(uint256)" --rpc-url "$RPC_URL"
cast call <DJED_ADDRESS> "reserveRatioMin()(uint256)" --rpc-url "$RPC_URL"
cast call <SC_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS> --rpc-url "$RPC_URL"
```

If `ratio < reserveRatioMin`, buy more RC first.

## Common pitfalls

1. Dry-run instead of deployment
- If `--broadcast` is missing, no contract is actually deployed.

2. Wrong RPC scheme
- For local Anvil use `http://127.0.0.1:8545` (not `https://`).

3. Wrong frontend contract routing
- Djed address is protocol controller, not ERC20.
- Call ERC20 methods (`symbol`, `decimals`, `balanceOf`) on `SC_ADDRESS` or `RC_ADDRESS`, not Djed.

4. Using unsupported deployment enum path
- `MILKOMEDA_TESTNET` enum exists but has no local config block in `DeploymentParameters.sol`.
- For local workflow above, use args `0 0`.
