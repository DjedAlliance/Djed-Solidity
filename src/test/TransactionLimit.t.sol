// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";
import "../Djed.sol";
import "../mock/MockOracle.sol";
import "./Utilities.sol";

contract TransactionLimitTest is CTest, Utilities {
    MockOracle oracle;
    Djed djed;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        THRESHOLD_NUMBER_SC = 0.5 * 1e6; // 0.5 SC
        TX_LIMIT = 2e6; // 2 SC

        oracle = new MockOracle(ORACLE_EXCHANGE_RATE);
        djed = (new Djed){value: INITIAL_BALANCE}(
            address(oracle),
            SCALING_FACTOR,
            TREASURY,
            INITIAL_TREASURY_FEE,
            TREASURY_REVENUE_TARGET,
            RESERVE_RATIO_MIN,
            RESERVE_RATIO_MAX,
            FEE,
            THRESHOLD_NUMBER_SC,
            RESERVE_COIN_WHOLE_MINIMUM_PRICE,
            RESERVE_COIN_WHOLE_INITIAL_PRICE,
            TX_LIMIT
        );
        cheats.deal(account1, 100 ether);
        cheats.deal(account2, 100 ether);

        // Verify Djed parameters:
        assertTrue(RESERVE_RATIO_MIN > (SCALING_FACTOR + FEE));
        assertTrue(RESERVE_RATIO_MAX >= RESERVE_RATIO_MIN);
        assertTrue((FEE > 0) && (SCALING_FACTOR >= FEE));
        assertTrue(THRESHOLD_NUMBER_SC > 0);
        assertTrue(RESERVE_COIN_WHOLE_MINIMUM_PRICE > 0);
        assertTrue(ORACLE_EXCHANGE_RATE > 0);
    }

    function testBuyStableCoinsBelowTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        /*
         * BC after deducting fees = 0.99 ADA
         * SC received = 1.98 SC < txLimit (1 SC = 0.5 ADA)
         */

        assertEq(djed.stableCoin().balanceOf(account1), 3.96 * 1e6);
    }

    function testCannotBuyStableCoinsAboveTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Increasing buy amount by small amount to revert tx
        uint256 smallAmountBC = 0.011 * 1e18; // 0.011 ADA
        buyAmount += smallAmountBC; // 1.011 ADA

        cheats.prank(account1);
        cheats.expectRevert("buySC: tx limit exceeded");
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        /*
         * BC after deducting fees = 1.00089 ADA (1% fee)
         * SC received = 2.00178 SC (> txLimit)
         */

        // Balance didn't change second time
        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
    }

    function testSellStableCoinsBelowTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Buying 2 times - 2 ADA
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        /*
         * BC after deducting fees = 1.98 ADA
         * SC received = 1.98 + 1.98 = 3.96 SC
         */

        assertEq(djed.stableCoin().balanceOf(account1), 5.94 * 1e6); // 1.98 + 3.96 SC

        // Selling exactly equal to txLimit (2 SC)
        uint256 sellAmount = TX_LIMIT; // 2 SC

        cheats.prank(account1);
        djed.sellStableCoins(sellAmount, account1, 0, address(0));

        assertEq(djed.stableCoin().balanceOf(account1), 3.94 * 1e6); // 5.94 - 2 SC
    }

    function testCannotSellStableCoinsAboveTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Buying 2 times - 2 ADA
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0));

        /*
         * BC after deducting fees = 1.98 ADA
         * SC received = 1.98 + 1.98 = 3.96 SC
         */

        assertEq(djed.stableCoin().balanceOf(account1), 5.94 * 1e6); // 1.98 + 3.96 SC

        // Selling little more than txLimit (2 SC)
        uint256 sellAmount = TX_LIMIT + 1; // 2.000001 SC

        cheats.prank(account1);
        cheats.expectRevert("sellSC: tx limit exceeded");
        djed.sellStableCoins(sellAmount, account1, 0, address(0));

        assertEq(djed.stableCoin().balanceOf(account1), 5.94 * 1e6);
    }

    function testBuyReserveCoinsBelowTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Buying 2 more times to decrease Reserve Ratio (should be less than R.R.max)
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        // Buying reserve coin
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account1, 0, address(0)); // 1 ADA

        /*
         * BC after deducting fees = 0.99 ADA
         * RC received = 0.99 RC (1 RC = 1 ADA)
         * Equivalent SC = 1.98 (n * rcPrice / scPrice)
         */

        assertEq(djed.reserveCoin().balanceOf(account1), 0.99 * 1e6);
    }

    function testCannotBuyReserveCoinsAboveTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Enforcing tx limit check
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        assertEq(djed.stableCoin().balanceOf(account1), 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Increasing buy amount by small amount to revert tx
        uint256 smallAmountBC = 0.011 * 1e18; // 0.011 ADA
        buyAmount += smallAmountBC; // 1.011 ADA

        cheats.prank(account1);
        cheats.expectRevert("buyRC: tx limit exceeded");
        djed.buyReserveCoins{value: buyAmount}(account1, 0, address(0));

        /*
         * BC after deducting fees =  1.00089 ADA (1% fee)
         * RC received = 1.00089 RC (1 RC = 1 ADA)
         * Equivalent SC = 2.00178 (n * rcPrice / scPrice)
         */

        assertEq(djed.reserveCoin().balanceOf(account1), 0);
    }

    /*
     * scPrice = min(0.5, R()/nSC)     0.5 = ORACLE EXCHANGE RATE
     * rcPrice = max((R() - nSC * scPrice) / nRC, 1)       1 = rcMinPrice
     */

    function testSellReserveCoinsBelowTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Buying 3 times to decrease Reserve Ratio (should be less than R.R.max) (Increase Reserve by 3)
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        // Checking tx limit checks should be applicable
        assertEq(djed.stableCoin().balanceOf(account1), 3 * 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Buying reserve coin (Increase Reserve by 1)
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account1, 0, address(0)); // 1 ADA

        /*
         * BC after deducting fees = 0.99 ADA
         * RC received = 0.99 RC (1 RC = 1 ADA)
         * Equivalent SC = 1.98 (n * rcPrice / scPrice)
         */

        assertEq(djed.reserveCoin().balanceOf(account1), 0.99 * 1e6);

        // Selling 5 SC to increase Reserve Ratio (Decrease Reserve by 2.5)
        cheats.prank(account1);
        djed.sellStableCoins(2e6, account1, 0, address(0)); // 2 SC

        cheats.prank(account1);
        djed.sellStableCoins(2e6, account1, 0, address(0)); // 2 SC

        cheats.prank(account1);
        djed.sellStableCoins(1 * 1e6, account1, 0, address(0)); // 1 SC

        /*
         * Actual values will be different due to inclusion of fees
         * R() = ~2.5     (1 + 3 + 1 - 2.5)
         * nSC = ~1
         * nRC = ~1
         * scPrice = min(0.5, 2.5/1) = 0.5
         * rcPrice = max((2.5 - 1 * 0.5) / 1, 1) = 2
         * n * rcPrice / scPrice < txLimit      (n -> no. or reserve coins to sell)
         * => n < 2 * 0.5 / 2
         * => n < 0.5
         * Actual value for n should be more lesser than 0.5 due to inclusion of fees
         */

        cheats.prank(account1);
        djed.sellReserveCoins(0.48 * 1e6, account1, 0, address(0));
    }

    function testCannotSellReserveCoinsBelowTxLimit() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Buying 3 times to decrease Reserve Ratio (should be less than R.R.max) (Increase Reserve by 3)
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, address(0)); // 1.98 SC

        // Checking tx limit checks should be applicable
        assertEq(djed.stableCoin().balanceOf(account1), 3 * 1.98 * 1e6);
        assertTrue(djed.stableCoin().totalSupply() > THRESHOLD_NUMBER_SC);

        // Buying reserve coin (Increase Reserve by 1)
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account1, 0, address(0)); // 1 ADA

        /*
         * BC after deducting fees = 0.99 ADA
         * RC received = 0.99 RC (1 RC = 1 ADA)
         * Equivalent SC = 1.98 (n * rcPrice / scPrice)
         */

        assertEq(djed.reserveCoin().balanceOf(account1), 0.99 * 1e6);

        // Selling 5 SC to increase Reserve Ratio (Decrease Reserve by 2.5)
        cheats.prank(account1);
        djed.sellStableCoins(2e6, account1, 0, address(0)); // 2 SC

        cheats.prank(account1);
        djed.sellStableCoins(2e6, account1, 0, address(0)); // 2 SC

        cheats.prank(account1);
        djed.sellStableCoins(1 * 1e6, account1, 0, address(0)); // 1 SC

        /*
         * Actual values will be different due to inclusion of fees
         * R() = ~2.5     (1 + 3 + 1 - 2.5)
         * nSC = ~1
         * nRC = ~1
         * scPrice = min(0.5, 2.5/1) = 0.5
         * rcPrice = max((2.5 - 1 * 0.5) / 1, 1) = 2
         * n * rcPrice / scPrice < txLimit      (n -> no. or reserve coins to sell)
         * => n < 2 * 0.5 / 2
         * => n < 0.5
         * Actual value for n should be more lesser than 0.5 to pass the tx limit check due to inclusion of fees
         */

        cheats.prank(account1);
        cheats.expectRevert("sellRC: tx limit exceeded");
        djed.sellReserveCoins(0.49 * 1e6, account1, 0, address(0));
    }
}
