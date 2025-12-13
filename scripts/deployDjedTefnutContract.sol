// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./DeploymentParameters.sol";
import {DjedTefnut} from "../src/DjedTefnut.sol";

contract DeployDjedTefnut is Script, DeploymentParameters {
    function run(SupportedNetworks network, SupportedVersion version) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);
        
        (
            address oracleAddress,
            address treasuryAddress,
            uint256 scalingFactor,
            uint256 treasuryFee,
            ,  // treasuryRevenueTarget - unused
            ,  // reserveRatioMin - unused
            ,  // reserveRatioMax - unused
            uint256 fee,
            uint256 thresholdSupplySc,
            uint256 rcMinPrice,
            uint256 rcInitialPrice,
            uint256 txLimit
        ) = getConfigFromNetwork(network, version);

        DjedTefnut djedTefnut = new DjedTefnut(
            oracleAddress,
            scalingFactor,
            treasuryAddress,
            treasuryFee,
            fee,
            thresholdSupplySc,
            rcMinPrice,
            rcInitialPrice,
            txLimit
        );

        console.log("DjedTefnut deployed at:", address(djedTefnut));
        vm.stopBroadcast();
    }
}
