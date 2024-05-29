// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ChainlinkOracle} from "../src/ChainlinkOracle.sol";
import {ChainlinkInvertingOracle} from "../src/ChainlinkInvertingOracle.sol";

contract DeployChainlinkOracle is Script {
    address constant CHAINLINK_DATA_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD
    uint256 constant DECIMALS = 18; // decimals of native coin

    function deploy2() external {
        // Djed contract requires an instance of ChainlinkInvertingOracle as it returns USD -> ETH
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        ChainlinkInvertingOracle chainlinkInvertingOracle = new ChainlinkInvertingOracle(
                CHAINLINK_DATA_FEED,
                DECIMALS
            );

        console.log(
            "ChainlinkOracle inverted deployed: ",
            address(chainlinkInvertingOracle)
        );
        vm.stopBroadcast();
    }

    function deploy() external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        ChainlinkOracle chainlinkOracle = new ChainlinkOracle(
            CHAINLINK_DATA_FEED,
            DECIMALS
        );

        console.log("ChainlinkOracle deployed: ", address(chainlinkOracle));
        vm.stopBroadcast();
    }
}