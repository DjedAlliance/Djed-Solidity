// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

contract ChainlinkOracle is IOracle {
    AggregatorV3Interface internal dataFeed;
    uint256 public immutable decimals;

    constructor(address _dataFeedAddress, uint256 _decimals) {

        dataFeed = AggregatorV3Interface(_dataFeedAddress);
        decimals = _decimals;
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {

        uint8 chainlinkDecimals = dataFeed.decimals();
        (, int answer,,,) = dataFeed.latestRoundData();
        require(answer >= 0, "Cannot convert negative value");
        return (uint256(int256(answer)) * (10 ** decimals) / (10 ** uint256(chainlinkDecimals)));
    }
}