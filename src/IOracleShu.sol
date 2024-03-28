// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

interface IOracle {
    function acceptTermsOfService() external;

    function readMaxPrice() external view returns (uint256);

    function readMinPrice() external view returns (uint256);
}