// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

contract ChainlinkOracle is IOracle {
    AggregatorV3Interface internal dataFeed;
    uint256 public immutable scalingFactor;

    constructor(address _dataFeedAddress, uint256 _decimals) {

        dataFeed = AggregatorV3Interface(_dataFeedAddress);
        scalingFactor = 10 ** (_decimals - uint256(dataFeed.decimals()));
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {

        (, int answer,,,) = dataFeed.latestRoundData();
        require(answer >= 0, "Cannot convert negative value");
        return (uint256(int256(answer)) * scalingFactor);
    }
}