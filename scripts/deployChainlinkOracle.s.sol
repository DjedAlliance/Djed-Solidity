// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {ChainlinkOracle} from "../src/ChainlinkOracle.sol";

contract DeployChainlinkOracle is Script, Helper {
    function run(SupportedNetworks network) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        (, address chainlinkDataFeed, ) = getConfigFromNetwork(network);

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
