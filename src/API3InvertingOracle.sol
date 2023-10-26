// SPDX-License-Identifier: AEL
pragma solidity ^0.7.0;

import "@api3dao/contracts/v0.7/interfaces/IProxy.sol";

contract API3InvertingOracle {
    address public immutable proxyAddress;
    uint256 public immutable scalingFactor;

    constructor(address _proxyAddress, uint256 _api3Decimals, uint256 _decimals) {

        proxyAddress = _proxyAddress;
        scalingFactor = 10 ** (_api3Decimals + _decimals);
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        (int224 value, ) = IProxy(proxyAddress).read();
        return (scalingFactor) / uint256(int256(value));
    }
}