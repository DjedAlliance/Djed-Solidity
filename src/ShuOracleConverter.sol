// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./IOracle.sol";
import "./IOracleShu.sol";

contract ShuOracleConverter is IOracleShu {
    IOracle public oracle;
    uint8 public previousHour;
    uint256 public lastTimestamp;
    uint256 public previousPrice;
    uint256 private _currentMaxPrice;
    uint256 private _currentMinPrice;
    uint256[24] public movingPrice;

    constructor(address oracleAddress) {
        oracle = IOracle(oracleAddress);
        previousHour = 0;
        previousPrice = oracle.readData();
        _currentMaxPrice = previousPrice;
        _currentMinPrice = previousPrice;
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
        if (currentHour != previousHour && lastTimestamp < block.timestamp) {
            for (uint8 i = previousHour; i < currentHour; i++) {
                movingPrice[i] = previousPrice;
            }
            movingPrice[currentHour] = oracle.readData();
            previousPrice = movingPrice[currentHour];
            previousHour = currentHour;
            lastTimestamp = block.timestamp;
            (_currentMinPrice, _currentMaxPrice) = _calculateMinMaxPrice();
        }
    }

    function _getHourDifference(
        uint256 currentTime
    ) internal pure returns (uint8) {
        return uint8((currentTime / (1 hours)) % 24);
    }

    function _calculateMinMaxPrice() internal view returns (uint256, uint256) {
        uint256 min = movingPrice[0];
        uint256 max = movingPrice[0];

        for (uint256 i = 1; i < 24; i++) {
            if (movingPrice[i] < min) {
                min = movingPrice[i];
            }
            if (movingPrice[i] > max) {
                max = movingPrice[i];
            }
        }

        return (min, max);
    }
}
