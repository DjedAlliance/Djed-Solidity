// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./DeploymentParameters.sol";
import {ShuOracleConverter} from "../src/ShuOracleConverter.sol";

contract DeployOracleConverter is Script, DeploymentParameters {
    function run(SupportedNetworks network, SupportedVersion version) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(senderPrivateKey);

        (address oracleAddress, , , , , , , , , , , ) = getConfigFromNetwork(
            network, version
        );

        ShuOracleConverter oracleConverter = new ShuOracleConverter(
            oracleAddress
        );

        console.log(
            "Shu Oracle Converter deployed: ",
            address(oracleConverter)
        );
        vm.stopBroadcast();
    }
}
