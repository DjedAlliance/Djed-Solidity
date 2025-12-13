// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/DjedTefnut.sol";
import "./DeploymentParameters.sol";

contract DeployDjedTefnutContract is Script, DeploymentParameters {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get configuration for Tefnut deployment
        (
            address oracleAddress,
            address treasuryAddress,
            uint256 scalingFactor,
            uint256 treasuryFeeFixed,
            uint256 fee,
            uint256 thresholdSupplySC,
            uint256 rcMinPrice,
            uint256 rcInitialPrice,
            uint256 txLimit
        ) = getTefnutConfigFromNetwork(
            SupportedNetworks.ETHEREUM_CLASSIC_MORDOR // Change network as needed
        );

        console.log("Deploying DjedTefnut with following parameters:");
        console.log("Oracle Address:", oracleAddress);
        console.log("Treasury Address:", treasuryAddress);
        console.log("Scaling Factor:", scalingFactor);
        console.log("Treasury Fee (Fixed):", treasuryFeeFixed);
        console.log("Protocol Fee:", fee);
        console.log("Threshold Supply SC:", thresholdSupplySC);
        console.log("RC Minimum Price:", rcMinPrice);
        console.log("RC Initial Price:", rcInitialPrice);
        console.log("Transaction Limit:", txLimit);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy DjedTefnut with initial reserve
        DjedTefnut djed = new DjedTefnut{value: 1 ether}(
            oracleAddress,
            scalingFactor,
            treasuryAddress,
            treasuryFeeFixed,
            fee,
            thresholdSupplySC,
            rcMinPrice,
            rcInitialPrice,
            txLimit
        );

        console.log("\n=== Deployment Successful ===");
        console.log("DjedTefnut Contract:", address(djed));
        console.log("StableCoin (SC):", address(djed.stableCoin()));
        console.log("ReserveCoin (RC):", address(djed.reserveCoin()));
        console.log("Initial Reserve:", address(djed).balance);

        vm.stopBroadcast();
    }
}
