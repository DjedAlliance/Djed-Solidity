// SPDX-License-Identifier: AEL
pragma solidity ^0.7.0;

import "@api3dao/contracts/v0.7/interfaces/IProxy.sol";

contract API3Oracle {
    address public proxyAddress;
    uint256 public ADDITIONAL_DECIMALS_PRECISION;
    uint256 public DJED_DECIMALS;

    constructor(address _proxyAddress, uint256 _api3_DECIMALS, uint256 _djed_DECIMALS) {

        require(_djed_DECIMALS > _api3_DECIMALS, "value returned from api3 oracle has higher precision");
        proxyAddress = _proxyAddress;
        ADDITIONAL_DECIMALS_PRECISION = _djed_DECIMALS / _api3_DECIMALS;
        DJED_DECIMALS = _djed_DECIMALS;
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        (int224 value, ) = IProxy(proxyAddress).read();

        require(value >= 0, "Cannot convert negative value");
        return (uint256(int256(value)) * ADDITIONAL_DECIMALS_PRECISION) / DJED_DECIMALS;
    }
}
