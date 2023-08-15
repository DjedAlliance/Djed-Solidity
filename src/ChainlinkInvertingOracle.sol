// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

contract ChainlinkInvertingOracle is IOracle{
    AggregatorV3Interface internal dataFeed;
    uint256 public immutable linkDecimals;
    uint256 public immutable decimals;

    constructor(address _dataFeedAddress, uint256 _linkDecimals, uint256 _decimals) {

        dataFeed = AggregatorV3Interface(_dataFeedAddress);
        linkDecimals = _linkDecimals;
        decimals = _decimals;
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        (, int answer,,,) = dataFeed.latestRoundData();

        require(answer >= 0, "Cannot convert negative value");
        require((uint256(int256(answer))) < (decimals * linkDecimals), "value returned has higher precision");
        return (decimals * linkDecimals) / uint256(int256(answer));
    }
}