// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import {IOracleShu} from "../IOracleShu.sol";

/**
 * @title MockShuOracleTefnut
 * @notice Mock implementation of IOracleShu for testing DjedTefnut
 * @dev Provides controllable price feeds for testing scenarios
 */
contract MockShuOracleTefnut is IOracleShu {
    uint256 public maxPrice;
    uint256 public minPrice;
    uint256 public lastUpdateTimestamp;

    constructor(uint256 _price) {
        maxPrice = _price;
        minPrice = _price;
        lastUpdateTimestamp = block.timestamp;
    }

    /// @notice Accept terms of service (no-op for mock)
    function acceptTermsOfService() external override {
        // No-op for mock
    }

    /// @notice Returns the maximum price and timestamp
    /// @return price The maximum price in weis per whole stablecoin
    /// @return timestamp The timestamp of the last update
    function readMaxPrice() external view override returns (uint256 price, uint256 timestamp) {
        return (maxPrice, lastUpdateTimestamp);
    }

    /// @notice Returns the minimum price and timestamp
    /// @return price The minimum price in weis per whole stablecoin
    /// @return timestamp The timestamp of the last update
    function readMinPrice() external view override returns (uint256 price, uint256 timestamp) {
        return (minPrice, lastUpdateTimestamp);
    }

    /// @notice Update oracle values (no-op for mock, updates timestamp)
    function updateOracleValues() external override {
        lastUpdateTimestamp = block.timestamp;
    }

    // ============ Test Helper Functions ============

    /// @notice Set both max and min price to the same value
    /// @param _price The new price in weis per whole stablecoin
    function setPrice(uint256 _price) external {
        maxPrice = _price;
        minPrice = _price;
        lastUpdateTimestamp = block.timestamp;
    }

    /// @notice Set max and min prices separately
    /// @param _maxPrice The new maximum price
    /// @param _minPrice The new minimum price
    function setPrices(uint256 _maxPrice, uint256 _minPrice) external {
        require(_maxPrice >= _minPrice, "Max price must be >= min price");
        maxPrice = _maxPrice;
        minPrice = _minPrice;
        lastUpdateTimestamp = block.timestamp;
    }

    /// @notice Increase price by a specified amount
    /// @param amount The amount to increase the price by
    function increasePrice(uint256 amount) external {
        maxPrice += amount;
        minPrice += amount;
        lastUpdateTimestamp = block.timestamp;
    }

    /// @notice Decrease price by a specified amount
    /// @param amount The amount to decrease the price by
    function decreasePrice(uint256 amount) external {
        require(maxPrice >= amount && minPrice >= amount, "Price cannot go negative");
        maxPrice -= amount;
        minPrice -= amount;
        lastUpdateTimestamp = block.timestamp;
    }
}
