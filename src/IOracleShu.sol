// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

interface IOracleShu {
    function acceptTermsOfService() external;

    function readMaxPrice() external view returns (uint256, uint256); // returns (maxPrice, timestamp)

    function readMinPrice() external view returns (uint256, uint256); // returns (minPrice, timestamp)

    function updateOracleValues() external;
}
