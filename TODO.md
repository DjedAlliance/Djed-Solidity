# Djed Tefnut Implementation Plan

## Information Gathered:
- Current DjedShu implementation with reserve ratio constraints, sellBothCoins function, and linear treasury fee decay
- Oracle interface (IOracleShu) with dual-oracle logic (max/min prices)
- Deployment infrastructure with parameter configurations
- Test files that reference sellBothCoins functionality


## Plan: Detailed Code Update Plan (REVISED)


### Step 1: Create DjedTefnut.sol by Forking DjedShu ✅ COMPLETED
- Create DjedTefnut that inherits from DjedShu (minimal reimplementation)
- Remove reserve ratio constraints:
  - Remove `reserveRatioMin` and `reserveRatioMax` parameters from constructor
  - Remove `isRatioAboveMin()` and `isRatioBelowMax()` functions
  - Remove ratio validation checks in trading functions
  - Remove `ratioMax()` and `ratioMin()` functions
- Remove `sellBothCoins()` function completely (all implementations and calls)
- Remove linear treasury fee decay mechanism:
  - Remove `treasuryRevenue` tracking variable
  - Simplify `treasuryFee()` to return constant `initialTreasuryFee`
- Preserve dual-oracle logic exactly as-is
- Update events (remove SoldBothCoins event)

### Step 2: Update Deployment Configuration ✅ COMPLETED
- Add minimal Tefnut configuration to existing deployment scripts
- Reuse ETH-based deployment flow, just add Tefnut version

### Step 3: Create Targeted Tests ✅ COMPLETED
- Create DjedTefnut test file focused on removed features verification
- Test that removed features are not callable
- Test mint/redeem works with both oracle prices
- Ensure behavior identical to Shu except removed constraints

### Step 4: Verify Implementation ✅ COMPLETED
- Compile contracts successfully
- Run tests to verify core functionality
- Ensure deployment compatibility

## Summary of Changes Made:

### DjedTefnut.sol Contract:
1. ✅ **Removed reserve ratio constraints**: Eliminated `reserveRatioMin`, `reserveRatioMax` parameters and related validation functions (`isRatioAboveMin`, `isRatioBelowMax`, `ratioMax`, `ratioMin`)
2. ✅ **Removed sellBothCoins function**: Completely eliminated the `sellBothCoins()` function and `SoldBothCoins` event
3. ✅ **Removed linear treasury fee decay**: Simplified `treasuryFee()` to return constant `initialTreasuryFee`, removed `treasuryRevenue` tracking
4. ✅ **Preserved dual-oracle logic**: Maintained all oracle interface functionality and price reading mechanisms
5. ✅ **Updated constructor**: Removed unused parameters, simplified parameter list

### Deployment Configuration:
- ✅ **Created deployment script**: `deployDjedTefnutContract.sol` with proper parameter configuration
- ✅ **Updated foundry.toml**: Added `via_ir = true` to handle compiler stack depth issues

### Test Coverage:
- ✅ **Created comprehensive tests**: `DjedTefnut.t.sol` with tests for:
  - Removed functions verification (bytecode scanning)
  - Treasury fee constant behavior
  - Basic mint/redeem functionality
  - Oracle price integration
  - Constructor parameter validation

### Key Features Removed:
- ❌ `reserveRatioMin` and `reserveRatioMax` parameters
- ❌ `sellBothCoins()` function 
- ❌ `isRatioAboveMin()` and `isRatioBelowMax()` functions
- ❌ `ratioMax()` and `ratioMin()` functions
- ❌ Linear treasury fee decay mechanism
- ❌ `treasuryRevenue` tracking variable
- ❌ `SoldBothCoins` event

### Key Features Preserved:
- ✅ Dual-oracle logic (max/min prices)
- ✅ Core mint/redeem flows
- ✅ ETH-based deployment infrastructure
- ✅ Treasury fee collection (constant rate)
- ✅ Transaction limits and safety checks

## Acceptance Criteria Status:
- ✅ **Contracts compile and deploy successfully**: All contracts compile without errors
- ✅ **All removed features are fully eliminated**: Verified through bytecode analysis and compilation tests
- ✅ **Core mint/redeem flows work with two oracle prices**: Tests confirm dual-oracle functionality preserved
- ✅ **Compatibility with existing ETH-based deployment flow**: Deployment script integrates with existing infrastructure

## Files Created/Modified:
1. `src/DjedTefnut.sol` - New simplified contract
2. `scripts/deployDjedTefnutContract.sol` - Deployment script
3. `src/test/DjedTefnut.t.sol` - Test suite
4. `foundry.toml` - Updated for via_ir compilation
5. `TODO.md` - This implementation plan (completed)
