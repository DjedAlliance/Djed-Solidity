// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ChainlinkOracle} from "../src/ChainlinkOracle.sol";
import {ChainlinkInvertingOracle} from "../src/ChainlinkInvertingOracle.sol";

contract DeployChainlinkOracle is Script {
    function run() external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        address chainlinkDataFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD
        uint256 DJED_DECIMALS = 6;

        vm.startBroadcast(senderPrivateKey);

        ChainlinkOracle chainlinkOracle = new ChainlinkOracle(
            chainlinkDataFeed, DJED_DECIMALS
        );

        console.log(
            "ChainlinkOracle deployed: ",
            address(chainlinkOracle)
        );
        vm.stopBroadcast();
    }
}

contract DeployInvertingChainlinkOracle is Script {
    function run() external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        address chainlinkDataFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD
        uint256 DJED_DECIMALS = 6;

        vm.startBroadcast(senderPrivateKey);

        ChainlinkInvertingOracle chainlinkInvertingOracle = new ChainlinkInvertingOracle(
            chainlinkDataFeed, DJED_DECIMALS
        );

        console.log(
            "ChainlinkOracle deployed: ",
            address(chainlinkInvertingOracle)
        );
        vm.stopBroadcast();
    }
}