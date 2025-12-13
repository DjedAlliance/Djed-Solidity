// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "../IOracleShu.sol";

contract MockShuOracle is IOracleShu {
    uint256 public exchangeRate;
    uint256 public lastUpdate;

    constructor(uint256 _exchangeRate) {
        exchangeRate = _exchangeRate;
        lastUpdate = block.timestamp;
    }

    function readData() external view returns (uint256) {
        return exchangeRate;
    }

    function readMaxPrice() external view override returns (uint256, uint256) {
        return (exchangeRate, lastUpdate);
    }

    function readMinPrice() external view override returns (uint256, uint256) {
        return (exchangeRate, lastUpdate);
    }

    function updateOracleValues() external override {
        lastUpdate = block.timestamp;
    }

    function increasePrice() external {
        exchangeRate += 1e17;
    }

    function decreasePrice() external {
        exchangeRate -= 1e17;
    }

    function setPrice(uint256 newPrice) external {
        exchangeRate = newPrice;
    }

    function acceptTermsOfService() external override {}
}
