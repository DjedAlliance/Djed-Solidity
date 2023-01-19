// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";
import "../Djed.sol";
import "../mock/MockOracle.sol";
import "./Utilities.sol";

contract MinimalDjedTest is CTest, Utilities {
    MockOracle oracle;
    Djed djed;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
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

    function testInitialBalance() public {
        assertEq(R(djed), INITIAL_BALANCE);
    }

    function testBuyStableCoins() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
        assertEq(djed.stableCoin().balanceOf(account1), 1980000); // 1.98 SC
        assertEq(djed.stableCoin().totalSupply(), 1980000);
        assertEq(djed.reserveCoin().totalSupply(), 0);
        assertEq(R(djed), 2e18); // 2 ADA
    }

    function testSellStableCoins() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
        assertEq(djed.stableCoin().balanceOf(account1), 1980000); // 1.98 SC
        assertEq(djed.stableCoin().totalSupply(), 1980000);
        assertEq(djed.reserveCoin().totalSupply(), 0);
        assertEq(R(djed), 2e18); // 2 ADA
        cheats.prank(account1);
        djed.sellStableCoins(1980000, account1, 0, address(0));
        assertEq(djed.stableCoin().balanceOf(account1), 0); // 1.98 SC
        assertEq(djed.stableCoin().totalSupply(), 0);
        assertEq(djed.reserveCoin().totalSupply(), 0);
        assertEq(R(djed), 10199e14); // 2 ADA
    }

    function testBuyReserveCoinsBelowThreshold() public {
        assertTrue(djed.stableCoin().totalSupply() <= THRESHOLD_NUMBER_SC);
        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
        assertEq(djed.stableCoin().balanceOf(account1), 0); // 0 SC
        assertEq(djed.reserveCoin().balanceOf(account1), 990000); // 0.99 RC
        assertEq(R(djed), 2e18); // 2 ADA
        assertEq(djed.stableCoin().totalSupply(), 0);
        assertEq(djed.reserveCoin().totalSupply(), 990000);
    }

    function testBuyReserveCoinsAboveThreshold() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 2e18}(account1, 0, address(0)); // 2 ADA

        assertEq(djed.stableCoin().balanceOf(account1), 3960000); // 3.96 SC
        assertTrue(djed.stableCoin().totalSupply() >= THRESHOLD_NUMBER_SC);
        assertTrue(
            R(djed) / 1e12 <= (L(djed) * RESERVE_RATIO_MAX) / SCALING_FACTOR
        );

        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e14}(account1, 0, address(0)); // 0.0001 ADA
        assertEq(djed.reserveCoin().totalSupply(), 99);
        assertEq(djed.reserveCoin().balanceOf(account1), 99); // 0.000099 RC
        assertEq(R(djed), 30001e14); // 3.0001 ADA
        assertEq(djed.stableCoin().totalSupply(), 3960000);
        assertEq(djed.reserveCoin().totalSupply(), 99);
    }

    function testCannotBuyReserveCoins() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 7e17}(account1, 0, address(0)); // 0.7 ADA

        assertEq(djed.stableCoin().balanceOf(account1), 1386000); // 1.386 SC
        assertTrue(djed.stableCoin().totalSupply() >= THRESHOLD_NUMBER_SC);

        cheats.expectRevert("buyRC: ratio above max");
        cheats.prank(account2);
        djed.buyReserveCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
    }

    function testCannotBuyStableCoins() public {
        cheats.prank(account1);
        cheats.expectRevert("buySC: ratio below min");
        djed.buyStableCoins{value: 100e18}(account1, 0, address(0)); // 100 ADA
    }

    function testCannotSellReserveCoins() public {
        cheats.prank(account1);
        djed.buyReserveCoins{value: 10e18}(account1, 0, address(0)); // 10 ADA
        assertEq(djed.reserveCoin().totalSupply(), 99e5); // 9.9 RC
        assertEq(djed.reserveCoin().balanceOf(account1), 99e5); // 9.9 RC
        assertEq(R(djed), 11e18); // 11 ADA
        assertEq(djed.stableCoin().totalSupply(), 0);

        cheats.prank(account1);
        djed.buyStableCoins{value: 90e18}(account1, 0, address(0)); // ~180 SC

        cheats.prank(account1);
        cheats.expectRevert("sellRC: ratio below min");
        djed.sellReserveCoins(99e5, account1, 0, address(0));
    }
}
