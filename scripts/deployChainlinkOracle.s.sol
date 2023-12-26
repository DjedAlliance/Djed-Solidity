// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ChainlinkOracle} from "../src/ChainlinkOracle.sol";

contract DeployReceiver is Script {
    function run() external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address _dataFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        uint256 _decimals = 6;

        vm.startBroadcast(senderPrivateKey);

        ChainlinkOracle chainlinkOracle = new ChainlinkOracle(
            _dataFeedAddress, _decimals
        );

        console.log(
            "ChainlinkOracle deployed: ",
            address(chainlinkOracle)
        );
        vm.stopBroadcast();
    }
}
