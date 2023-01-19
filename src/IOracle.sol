// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

interface IOracle {
    function acceptTermsOfService() external;

    function readData() external view returns (uint256);
}
