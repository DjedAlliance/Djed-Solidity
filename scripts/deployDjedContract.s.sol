// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {Djed} from "../src/Djed.sol";

contract DeployDjed is Script, Helper {
    function run(SupportedNetworks network) external {
        uint256 INITIAL_BALANCE = 0;
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(senderPrivateKey);
        (
            address oracleAddress,
            address treasuryAddress,
            uint256 SCALING_FACTOR,
            uint256 INITIAL_TREASURY_FEE,
            uint256 TREASURY_REVENUE_TARGET,
            uint256 RESERVE_RATIO_MIN,
            uint256 RESERVE_RATIO_MAX,
            uint256 FEE,
            uint256 THREASHOLD_SUPPLY_SC,
            uint256 RESERVE_COIN_MINIMUM_PRICE,
            uint256 RESERVE_COIN_INITIAL_PRICE,
            uint256 TX_LIMIT
        ) = getConfigFromNetwork(network);

        Djed djed = new Djed{value: INITIAL_BALANCE}(
            oracleAddress,
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
