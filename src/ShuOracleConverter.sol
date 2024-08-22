// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;
import "forge-std/console.sol";

import "./IOracle.sol";
import "./IOracleShu.sol";

contract ShuOracleConverter is IOracleShu {
    uint8 public constant UPDATE_TIME_IN_HOUR = 24;
    IOracle public oracle;
    uint256 public lastTimestamp;
    uint256 private _maxPrice;
    uint256 private _minPrice;
    uint256 private _updatesSinceHourStart = 0;
    uint256[UPDATE_TIME_IN_HOUR] public movingPrice;

    uint8 public previousHour;
    uint8 private _minPriceIndex;
    uint8 private _maxPriceIndex;

    constructor(address oracleAddress) {
        oracle = IOracle(oracleAddress);
        uint256 latestPrice = oracle.readData();
        lastTimestamp = block.timestamp;
        previousHour = uint8(
            (block.timestamp / (1 hours)) % UPDATE_TIME_IN_HOUR
        );

        for (uint8 i = 0; i < UPDATE_TIME_IN_HOUR; i++) {
            movingPrice[i] = latestPrice;
        }
        _maxPrice = latestPrice;
        _minPrice = latestPrice;
        _minPriceIndex = previousHour;
        _maxPriceIndex = previousHour;
    }

    function acceptTermsOfService() external {}

    function readMaxPrice() external view returns (uint256, uint256) {
        return (_maxPrice, block.timestamp);
    }

    function readMinPrice() external view returns (uint256, uint256) {
        return (_minPrice, block.timestamp);
    }

    function updateOracleValues() external {
        uint8 currentHour = uint8(
            (block.timestamp / (1 hours)) % UPDATE_TIME_IN_HOUR
        );
        if (block.timestamp / (1 hours) - previousHour >= 1) {
            _updatesSinceHourStart = 0;
            uint8 hourCount = (currentHour > previousHour)
                ? currentHour - previousHour
                : UPDATE_TIME_IN_HOUR + currentHour - previousHour;
            uint256 latestPrice = oracle.readData();

            for (uint8 i = 1; i < hourCount; i++) {
                movingPrice[
                    (previousHour + i) % UPDATE_TIME_IN_HOUR
                ] = latestPrice;
            }
            if (_shouldUpdateMinMax(_minPriceIndex, currentHour)) {
                _updateMinPrice();
            }
            if (_shouldUpdateMinMax(_maxPriceIndex, currentHour)) {
                _updateMaxPrice();
            }
            previousHour = currentHour;
        }

        uint256 latestAveragePrice = (movingPrice[currentHour] *
            _updatesSinceHourStart +
            oracle.readData()) / (_updatesSinceHourStart + 1);
        _updatesSinceHourStart++;

        movingPrice[currentHour] = latestAveragePrice;

        if (latestAveragePrice < _minPrice) {
            _minPrice = latestAveragePrice;
            _minPriceIndex = currentHour;
        } else if (latestAveragePrice > _maxPrice) {
            _maxPrice = latestAveragePrice;
            _maxPriceIndex = currentHour;
        }
        lastTimestamp = block.timestamp;
    }

    function _shouldUpdateMinMax(uint8 index, uint8 currentHour)
        internal
        view
        returns (bool)
    {
        if (previousHour <= currentHour) {
            return previousHour <= index && index <= currentHour;
        } else {
            return previousHour <= index || index <= currentHour;
        }
    }

    function _updateMinPrice() internal {
        uint256 min = type(uint256).max;

        for (uint8 i = 0; i < UPDATE_TIME_IN_HOUR; i++) {
            uint256 price = movingPrice[i];
            if (price < min) {
                _minPriceIndex = i;
                min = price;
            }
        }
        _minPrice = min;
    }

    function _updateMaxPrice() internal {
        uint256 max = 0;

        for (uint8 i = 0; i < UPDATE_TIME_IN_HOUR; i++) {
            uint256 price = movingPrice[i];
            if (price > max) {
                _maxPriceIndex = i;
                max = price;
            }
        }
        _maxPrice = max;
    }
}
