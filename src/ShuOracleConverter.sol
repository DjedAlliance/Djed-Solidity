// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;
import "forge-std/console.sol";

import "./IOracle.sol";
import "./IOracleShu.sol";

contract ShuOracleConverter is IOracleShu {
    uint8 public constant UPDATE_TIME_IN_HOUR = 24;
    IOracle public oracle;
    uint256 public lastTimestamp;
    uint256 private _currentMaxPrice;
    uint256 private _currentMinPrice;
    uint256 private iterations = 0;
    uint256[UPDATE_TIME_IN_HOUR] public movingPrice;

    uint8 public previousHour;
    uint8 private _minIndex;
    uint8 private _maxIndex;

    constructor(address oracleAddress) {
        oracle = IOracle(oracleAddress);
        uint256 latestPrice = oracle.readData();
        lastTimestamp = block.timestamp;
        previousHour = uint8(
            (block.timestamp / (1 hours)) % UPDATE_TIME_IN_HOUR
        );
        movingPrice[previousHour] = latestPrice;
        _currentMaxPrice = latestPrice;
        _currentMinPrice = latestPrice;
        _minIndex = previousHour;
        _maxIndex = previousHour;
    }

    function acceptTermsOfService() external {}

    function readMaxPrice() external view returns (uint256, uint256) {
        return (_currentMaxPrice, block.timestamp);
    }

    function readMinPrice() external view returns (uint256, uint256) {
        return (_currentMinPrice, block.timestamp);
    }

    function updateOracleValues() external {
        uint8 currentHour = uint8(
            (block.timestamp / (1 hours)) % UPDATE_TIME_IN_HOUR
        );
        if (currentHour != previousHour && lastTimestamp < block.timestamp) {
            iterations = 0;
            uint8 hourCount = (currentHour > previousHour)
                ? currentHour - previousHour
                : UPDATE_TIME_IN_HOUR + currentHour - previousHour;
            for (uint8 i = 1; i < hourCount; i++) {
                movingPrice[(previousHour + i) % UPDATE_TIME_IN_HOUR] = oracle
                    .readData();
            }
            if (_ifUpdateMinMax(_minIndex, currentHour)) {
                _updateMinPrice();
            }
            if (_ifUpdateMinMax(_maxIndex, currentHour)) {
                _updateMaxPrice();
            }
            previousHour = currentHour;
        }

        uint256 latestAveragePrice = (movingPrice[currentHour] *
            iterations +
            oracle.readData()) / (iterations + 1);
        iterations++;

        movingPrice[currentHour] = latestAveragePrice;

        if (latestAveragePrice < _currentMinPrice) {
            _currentMinPrice = latestAveragePrice;
            _minIndex = currentHour;
        } else if (latestAveragePrice > _currentMaxPrice) {
            _currentMaxPrice = latestAveragePrice;
            _maxIndex = currentHour;
        }
        lastTimestamp = block.timestamp;
    }

    function _ifUpdateMinMax(uint8 index, uint8 currentHour)
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
            if (price != 0 && price < min) {
                _minIndex = i;
                min = price;
            }
        }
        _currentMinPrice = min;
    }

    function _updateMaxPrice() internal {
        uint256 max = 0;

        for (uint8 i = 0; i < UPDATE_TIME_IN_HOUR; i++) {
            uint256 price = movingPrice[i];
            if (price > max) {
                _maxIndex = i;
                max = price;
            }
        }
        _currentMaxPrice = max;
    }
}
