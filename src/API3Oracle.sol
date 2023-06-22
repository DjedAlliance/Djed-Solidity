// SPDX-License-Identifier: AEL
pragma solidity ^0.7.0;

import "@api3dao/contracts/v0.7/interfaces/IProxy.sol";

contract API3Oracle {
    address public proxyAddress;

    constructor(address _proxyAddress) {
        proxyAddress = _proxyAddress;
    }

    function acceptTermsOfService() external{}

    function readData() external view returns (uint256) {
        (int224 value, ) = IProxy(proxyAddress).read();

        require(value >= 0, "Cannot convert negative value");

        return uint256(int256(value));
    }
}
