// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "airnode-protocol-v1/api3-server-v1/DapiServer.sol";

contract api3Oracle is DapiServer {
    bytes32 public dapiNameHash;

    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        bytes32 _dapiNameHash
    ) DapiServer(_accessControlRegistry, _adminRoleDescription, _manager) {
        dapiNameHash = _dapiNameHash;
    }

    function readData() external view returns (uint256) {
        int224 value;
        uint32 timestamp;

        (value, timestamp) = _readDataFeedWithDapiNameHash(dapiNameHash);
        int256 signedValue = int256(value);

        require(signedValue >= 0, "Cannot convert negative value");

        return uint256(signedValue);
    }
}
