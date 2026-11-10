// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";
import "../DjedShu.sol";
import "../ShuOracleConverter.sol";
import "../mock/MockShuOracle.sol";
import "./Utilities.sol";

contract DjedShuTest is CTest, Utilities {
    MockShuOracle private mockOracle;
    ShuOracleConverter private oracleConverter;
    DjedShu private djedShu;
    CheatCodes private cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        mockOracle = new MockShuOracle(ORACLE_EXCHANGE_RATE);
        oracleConverter = new ShuOracleConverter(address(mockOracle));
        djedShu = (new DjedShu){value: INITIAL_BALANCE}(
            address(oracleConverter),
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
    }

    function testShuRatioZeroLiabilitiesReturnsMax() public {
        assertEq(djedShu.stableCoin().totalSupply(), 0);
        assertEq(djedShu.ratioMax(), type(uint256).max);
        assertEq(djedShu.ratioMin(), type(uint256).max);
    }

    function testShuRatioWithLiabilities() public {
        cheats.prank(account1);
        djedShu.buyStableCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
        assertTrue(djedShu.stableCoin().totalSupply() > 0);

        uint256 liabilitiesMax = (djedShu.stableCoin().totalSupply() *
            djedShu.scMaxPrice(0)) / SC_DECIMAL_SCALING_FACTOR;
        uint256 liabilitiesMin = (djedShu.stableCoin().totalSupply() *
            djedShu.scMinPrice(0)) / SC_DECIMAL_SCALING_FACTOR;

        uint256 expectedRatioMax = (SCALING_FACTOR * address(djedShu).balance) /
            liabilitiesMax;
        uint256 expectedRatioMin = (SCALING_FACTOR * address(djedShu).balance) /
            liabilitiesMin;

        assertEq(djedShu.ratioMax(), expectedRatioMax);
        assertEq(djedShu.ratioMin(), expectedRatioMin);
    }

    function testShuRatioZeroLiabilitiesAfterSellingAllStableCoins() public {
        cheats.prank(account1);
        djedShu.buyStableCoins{value: 1e18}(account1, 0, address(0)); // 1 ADA
        assertTrue(djedShu.stableCoin().totalSupply() > 0);

        uint256 scBalance = djedShu.stableCoin().balanceOf(account1);
        cheats.prank(account1);
        djedShu.sellStableCoins(scBalance, account1, 0, address(0));
        assertEq(djedShu.stableCoin().totalSupply(), 0);
        assertEq(djedShu.ratioMax(), type(uint256).max);
        assertEq(djedShu.ratioMin(), type(uint256).max);
    }
}
