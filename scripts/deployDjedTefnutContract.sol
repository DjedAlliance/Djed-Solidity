// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./DeploymentParameters.sol";
import {DjedTefnut} from "../src/DjedTefnut.sol";

contract DeployDjedTefnut is Script, DeploymentParameters {
    function run(SupportedNetworks network, SupportedVersion version) external {
        uint256 INITIAL_BALANCE = 0;
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(senderPrivateKey);
        (
            address oracleAddress,
            address treasuryAddress,
            uint256 SCALING_FACTOR,
            uint256 INITIAL_TREASURY_FEE,
            uint256 FEE,
            uint256 THREASHOLD_SUPPLY_SC,
            uint256 RESERVE_COIN_MINIMUM_PRICE,
            uint256 RESERVE_COIN_INITIAL_PRICE,
            uint256 TX_LIMIT
        ) = getTefnutConfigFromNetwork(network, version);

        DjedTefnut djedTefnut = new DjedTefnut{value: INITIAL_BALANCE}(
            oracleAddress,
            SCALING_FACTOR,
            treasuryAddress,
            INITIAL_TREASURY_FEE,
            FEE,
            THREASHOLD_SUPPLY_SC,
            RESERVE_COIN_MINIMUM_PRICE,
            RESERVE_COIN_INITIAL_PRICE,
            TX_LIMIT
        );

        console.log(
            "Djed Tefnut contract deployed: ",
            address(djedTefnut)
        );
        vm.stopBroadcast();
    }

    function getTefnutConfigFromNetwork(
        SupportedNetworks network,
        SupportedVersion version
    )
        internal
        pure
        returns (
            address, address, 
            uint256, uint256, uint256, uint256, uint256, uint256, uint256
        )
    {
        // For Tefnut, we use the same oracle addresses as DjedShu but with simplified parameters
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (
                0xB9C050Fd340aD5ED3093F31aAFAcC3D779f405f4, // CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS
                0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA, // treasury address
                1e24, // SCALING_FACTOR
                25e20, // INITIAL_TREASURY_FEE
                15e21, // FEE
                5e11, // THREASHOLD_SUPPLY_SC
                1e18, // RESERVE_COIN_MINIMUM_PRICE
                1e20, // RESERVE_COIN_INITIAL_PRICE
                1e10 // TX_LIMIT
            );
        }

        if (network == SupportedNetworks.ETHEREUM_CLASSIC_MORDOR) {
            return (
                0x8Bd4A5F6a4727Aa4AC05f8784aACAbE2617e860A, // HEBESWAP_SHU_ORACLE_INVERTED_ADDRESS_MORDOR
                0xBC80a858F6F9116aA2dc549325d7791432b6c6C4, // treasury address
                1e24, // SCALING_FACTOR
                25e20, // INITIAL_TREASURY_FEE
                12500e18, // FEE
                10e6, // THREASHOLD_SUPPLY_SC
                1e15, // RESERVE_COIN_MINIMUM_PRICE
                1e18, // RESERVE_COIN_INITIAL_PRICE
                1e10 // TX_LIMIT
            );
        }

        if (network == SupportedNetworks.ETHEREUM_CLASSIC_MAINNET) {
            return (
                0x8Bd4A5F6a4727Aa4AC05f8784aACAbE2617e860A, // Using same as Mordor for now
                0xBC80a858F6F9116aA2dc549325d7791432b6c6C4, // treasury address
                1e24, // SCALING_FACTOR
                25e20, // INITIAL_TREASURY_FEE
                12500e18, // FEE
                10e6, // THREASHOLD_SUPPLY_SC
                1e15, // RESERVE_COIN_MINIMUM_PRICE
                1e18, // RESERVE_COIN_INITIAL_PRICE
                1e10 // TX_LIMIT
            );
        }

        // Default values (should not reach here)
        revert("Unsupported network for Tefnut deployment");
    }
}
