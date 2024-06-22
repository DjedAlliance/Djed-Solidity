// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;
import "forge-std/console.sol";

import "./IOracle.sol";
import "./IOracleShu.sol";

contract ShuOracleConverter is IOracleShu {
    IOracle public oracle;
    uint256 public lastTimestamp;
    uint256 private _currentMaxPrice;
    uint256 private _currentMinPrice;
    uint256[24] public movingPrice;

    uint8 public previousHour;
    uint8 private _minIndex;
    uint8 private _maxIndex;

    constructor(address oracleAddress) {
        oracle = IOracle(oracleAddress);
        uint256 latestPrice = oracle.readData();
        lastTimestamp = block.timestamp;
        previousHour = uint8((block.timestamp / (1 hours)) % 24);
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
        uint8 currentHour = _getHourDifference(block.timestamp);
        uint256 latestPrice = oracle.readData();
        movingPrice[currentHour] = latestPrice;

        if (currentHour != previousHour && lastTimestamp < block.timestamp) {
            for (uint8 i = previousHour + 1; i < currentHour; i++) {
                movingPrice[i] = latestPrice;
            }
            if (_ifUpdateMinMax(_minIndex, currentHour)) {
                _calculateMinPrice();
            }
            if (_ifUpdateMinMax(_maxIndex, currentHour)) {
                _calculateMaxPrice();
            }
            previousHour = currentHour;
        } else {
            // currentMinPrice was due to the latestPrice in this hour. But now latestPrice changes and is no longer minPrice. should we recalculate minPrice now?
            if (latestPrice < _currentMinPrice) {
                _currentMinPrice = latestPrice;
                _minIndex = currentHour;
            }

            if (latestPrice > _currentMaxPrice) {
                _currentMaxPrice = latestPrice;
                _maxIndex = currentHour;
            }
        }
        lastTimestamp = block.timestamp;
    }

    function _getHourDifference(
        uint256 currentTime
    ) internal pure returns (uint8) {
        return uint8((currentTime / (1 hours)) % 24);
    }

    function _ifUpdateMinMax(uint8 index, uint8 currentHour) internal view returns (bool) {
        if(previousHour <= currentHour) {
            return previousHour <= index && index <= currentHour;
        }
        else {
            return index >= previousHour || index <= currentHour;
        }
    }

    function _calculateMinPrice() internal {
        uint256 min = movingPrice[0];

        for (uint8 i = 1; i < 24; i++) {
            if (movingPrice[i] != 0 && movingPrice[i] < min) {
                _minIndex = i;
                min = movingPrice[i];
            }
        }
        _currentMinPrice = min;
    }

    function _calculateMaxPrice() internal {
        uint256 max = movingPrice[0];

        for (uint8 i = 1; i < 24; i++) {
            if (movingPrice[i] > max) {
                _maxIndex = i;
                max = movingPrice[i];
            }
        }
        _currentMaxPrice = max;
    }
}
