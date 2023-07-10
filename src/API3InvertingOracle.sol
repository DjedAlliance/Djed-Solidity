// SPDX-License-Identifier: AEL
pragma solidity ^0.7.0;

import "@api3dao/contracts/v0.7/interfaces/IProxy.sol";

contract API3InvertingOracle {
    address public immutable proxyAddress;
    uint256 public immutable api3Decimals;
    uint256 public immutable decimals;

    constructor(address _proxyAddress, uint256 _api3Decimals, uint256 _decimals) {

        proxyAddress = _proxyAddress;
        api3Decimals = _api3Decimals;
        decimals = _decimals;
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        (int224 value, ) = IProxy(proxyAddress).read();

        require(value >= 0, "Cannot convert negative value");
        require((uint256(int256(value))) < (decimals * api3Decimals), "value returned has higher precision");
        return (decimals * api3Decimals) / uint256(int256(value));
    }
}