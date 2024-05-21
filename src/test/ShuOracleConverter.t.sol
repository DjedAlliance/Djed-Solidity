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

        assertEq(uint256(oracleConverter.previousHour()), 0);
        assertEq(oracleConverter.previousPrice(), oracle.readData());

        (uint256 price, uint256 timestamp) = oracleConverter.readMaxPrice();
        assertEq(price, oracle.readData());

        (price, timestamp) = oracleConverter.readMinPrice();
        assertEq(price, oracle.readData());
        assertEq(block.timestamp, timestamp);
    }

    function test_updatePrice() public {
        oracle.updateData(); // increase oracle price by 1e17;
        skip(7200); // skips 2 hours;
        (uint256 currentMaxPrice, uint256 timestampMax) = oracleConverter
            .readMaxPrice();

        assertEq(currentMaxPrice, 5e17); // new oracle values have not been stored;

        oracleConverter.updateOracleValues(); // store new oracle values
        (currentMaxPrice, timestampMax) = oracleConverter.readMaxPrice();

        assertEq(currentMaxPrice, 6e17);
        oracle.updateData(); // increase oracle price by 1e17;

        oracleConverter.updateOracleValues(); // new oracle values need not be stored as 1 hour time has not passed, so max price remains the same;
        (currentMaxPrice, timestampMax) = oracleConverter.readMaxPrice();
        assertEq(currentMaxPrice, 6e17);

        skip(3600); // skip 1 hour;
        oracleConverter.updateOracleValues(); // store new oracle values
        (currentMaxPrice, timestampMax) = oracleConverter.readMaxPrice();
        assertEq(currentMaxPrice, 7e17);
    }
}

// forge test -vvvv --match-test "test_updatePrice"
