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

        assertEq(
            uint256(oracleConverter.previousHour()),
            uint8((block.timestamp / (1 hours)) % 24)
        );

        (uint256 priceMax, ) = oracleConverter.readMaxPrice();
        assertEq(priceMax, initialPrice);

        (uint256 priceMin, ) = oracleConverter.readMinPrice();
        assertEq(priceMin, initialPrice);
    }

    function test_updateOracleValues_noTimeElapsed() public {
        uint256 initialPrice = oracle.readData();
        oracle.increasePrice();

        oracleConverter.updateOracleValues();
        uint256 newPrice = oracle.readData();

        (uint256 maxPrice, ) = oracleConverter.readMaxPrice();
        (uint256 minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, newPrice);
        assertEq(minPrice, initialPrice);
    }

    function test_updateOracleValues_multipleHours() public {
        oracle.increasePrice();
        oracle.increasePrice();
        skip(3600 * 5); // Skip 5 hours

        uint256 firstUpdatePrice = oracle.readData();
        oracleConverter.updateOracleValues(); // First update after 5 hours

        oracle.decreasePrice();
        oracle.decreasePrice();
        oracle.decreasePrice();
        skip(3600 * 21); // Skip another 21 hours

        uint256 secondUpdatePrice = oracle.readData();
        oracleConverter.updateOracleValues(); // Second update after 21 hours

        (uint256 maxPrice, ) = oracleConverter.readMaxPrice();
        (uint256 minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, firstUpdatePrice);
        assertEq(minPrice, secondUpdatePrice);
    }

    function test_updateOracleValues_daysPassed() public {
        oracle.increasePrice();
        skip(3600 * 24 * 2); // Skip 2 days

        uint256 firstUpdatePrice = oracle.readData();
        oracleConverter.updateOracleValues(); // First update after 2 days

        uint8 liveHour = uint8((block.timestamp / (1 hours)) % 24);
        for (uint8 i = 0; i < 24; i++) {
            assertEq(
                oracleConverter.movingPrice(i),
                i == liveHour ? firstUpdatePrice : ORACLE_EXCHANGE_RATE
            ); // skipped hours carry the previous bucket forward
        }
        oracle.decreasePrice();
        oracle.decreasePrice();
        skip(3600 * 12); // Skip 12 hours

        uint256 secondUpdatePrice = oracle.readData();
        oracleConverter.updateOracleValues(); // Second update after 12 hours

        (uint256 maxPrice, ) = oracleConverter.readMaxPrice();
        (uint256 minPrice, ) = oracleConverter.readMinPrice();

        assertEq(maxPrice, firstUpdatePrice);
        assertEq(minPrice, secondUpdatePrice);
    }
}

// forge test -vvvv --match-path "src/test/ShuOracleConverter.t.sol"
