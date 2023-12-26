// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {Djed} from "../src/Djed.sol";

contract DeployDjed is Script, Helper {
    function run(SupportedNetworks network) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(senderPrivateKey);
        (address chainlinkOracle,, address treasuryAddress) = getConfigFromNetwork(network);
        Djed djed = new Djed(
            chainlinkOracle,
            SCALING_FACTOR,
            treasuryAddress,
            INITIAL_TREASURY_FEE,
            TREASURY_REVENUE_TARGET,
            RESERVE_RATIO_MIN,
            RESERVE_RATIO_MAX,
            FEE,
            THREASHOLD_SUPPLY_SC,
            RESERVE_COIN_MINIMUM_PRICE,
            RESERVE_COIN_INITIAL_PRICE,
            TX_LIMIT
        );

        console.log(
            "Djed contract deployed: ",
            address(djed)
        );
        vm.stopBroadcast();
    }
}
