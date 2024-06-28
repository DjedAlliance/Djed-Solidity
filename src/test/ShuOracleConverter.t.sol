// SPDX-License-Identifier: AEL
pragma solidity ^0.8.10;
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../ShuOracleConverter.sol";
import "../mock/MockShuOracle.sol";
import "./Utilities.sol";

contract OracleConverterTest is Test, Utilities {
    MockShuOracle public oracle;
    ShuOracleConverter public oracleConverter;

    function setUp() public {
        oracle = new MockShuOracle(ORACLE_EXCHANGE_RATE);
        oracleConverter = new ShuOracleConverter(address(oracle));
        uint256 initialPrice = oracle.readData();

        assertEq(uint256(oracleConverter.previousHour()), 0);

        (uint256 priceMax, ) = oracleConverter.readMaxPrice();
        assertEq(priceMax, initialPrice);

        (uint256 priceMin, ) = oracleConverter.readMinPrice();
        assertEq(priceMin, initialPrice);
    }

    function test_updateOracleValues_noTimeElapsed() public {
        uint256 initialPrice = oracle.readData();
        oracle.updateData();

        oracleConverter.updateOracleValues();
        uint256 newPrice = oracle.readData();

        (uint256 maxPrice, ) = oracleConverter.readMaxPrice();
        (uint256 minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, newPrice);
        assertEq(minPrice, initialPrice);
    }

    function test_updateOracleValues_hourDifference() public {
        uint256 initialPrice = oracle.readData(); // Set initial price
        oracle.updateData();
        skip(3600); // Skip 1 hour

        uint256 firstUpdatePrice = oracle.readData();

        oracleConverter.updateOracleValues(); // First update after 1 hour
        (uint256 maxPrice, ) = oracleConverter.readMaxPrice();
        (uint256 minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, firstUpdatePrice);
        assertEq(minPrice, initialPrice);

        // Second update with increased price
        oracle.updateData();
        skip(7200); // Skip 2 hours

        uint256 secondUpdatePrice = oracle.readData();

        oracleConverter.updateOracleValues(); // Second update after 2 hours

        (maxPrice, ) = oracleConverter.readMaxPrice();
        (minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, secondUpdatePrice);
        assertEq(minPrice, initialPrice);
    }
}

// forge test -vvvv --match-path "src/test/ShuOracleConverter.t.sol"
