// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

contract MockShuOracle {
    uint256 public exchangeRate;

    constructor(uint256 _exchangeRate) {
        exchangeRate = _exchangeRate;
    }

    function readData() external view returns (uint256) {
        return exchangeRate;
    }

    function updateData() external {
        exchangeRate += 1e17;
    }

    function acceptTermsOfService() external {}
}
