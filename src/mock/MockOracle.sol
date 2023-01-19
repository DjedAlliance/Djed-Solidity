// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

contract MockOracle {
    uint256 public immutable exchangeRate;

    mapping(address => bool) public acceptedTermsOfService;

    modifier onlyAcceptedTermsOfService() {
        require(acceptedTermsOfService[msg.sender], "Terms of service are not accepted");
        _;
    }

    constructor(uint256 _exchangeRate) {
        exchangeRate = _exchangeRate;
    }

    function readData() external view onlyAcceptedTermsOfService returns (uint256) {
        return exchangeRate;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }
}
