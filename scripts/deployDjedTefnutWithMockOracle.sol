// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {DjedTefnut} from "../src/DjedTefnut.sol";
import {MockShuOracle} from "../src/mock/MockShuOracle.sol";

contract DeployDjedTefnutWithMock is Script {
    function run() external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);
        
        // Deploy MockShuOracle with initial price of $1 (1e18)
        MockShuOracle oracle = new MockShuOracle(1e18);
        console.log("MockShuOracle deployed at:", address(oracle));

        // Deploy DjedTefnut with mock oracle
        DjedTefnut djedTefnut = new DjedTefnut(
            address(oracle),     // oracle address
            1e18,                // scalingFactor (1.0)
            msg.sender,          // treasury address (deployer)
            100,                 // treasuryFee (1%)
            200,                 // fee (2%)
            1000e18,             // thresholdSupplySc (1000 stable coins)
            1e15,                // rcMinPrice (0.001)
            1e17,                // rcInitialPrice (0.1)
            100e18               // txLimit (100 ETH)
        );

        console.log("DjedTefnut deployed at:", address(djedTefnut));
        vm.stopBroadcast();
    }
}
