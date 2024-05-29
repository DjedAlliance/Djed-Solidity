// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA,
        MILKOMEDA_TESTNET
    }

    mapping(SupportedNetworks enumValue => string humanReadableName)
        public networks;

    uint256 public SCALING_FACTOR;
    uint256 public INITIAL_TREASURY_FEE;
    uint256 public TREASURY_REVENUE_TARGET;
    uint256 public RESERVE_RATIO_MIN;
    uint256 public RESERVE_RATIO_MAX;
    uint256 public FEE;
    uint256 public THREASHOLD_SUPPLY_SC;
    uint256 public RESERVE_COIN_MINIMUM_PRICE;
    uint256 public RESERVE_COIN_INITIAL_PRICE;
    uint256 public TX_LIMIT;

    address constant CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS = 0x0e62e7df0bA9d9142B980c329a2B111735c954B5;
    address oracleAddress;
    address treasuryAddress;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.MILKOMEDA_TESTNET] = "Milkomeda C1 Testnet";
    }

    function getConfigFromNetwork(
        SupportedNetworks network
    )
        internal
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            oracleAddress = CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS;
            treasuryAddress = 0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA;
            SCALING_FACTOR = 1e24;
            INITIAL_TREASURY_FEE = 1e18;
            TREASURY_REVENUE_TARGET = 1e26;
            RESERVE_RATIO_MIN = 4e24;
            RESERVE_RATIO_MAX = 8e24;
            FEE = 15e24;
            THREASHOLD_SUPPLY_SC = 5e11;
            RESERVE_COIN_MINIMUM_PRICE = 1e18;
            RESERVE_COIN_INITIAL_PRICE = 1e20;
            TX_LIMIT = 1e10;
        }

        return (
            oracleAddress,
            treasuryAddress,
            SCALING_FACTOR,
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
    }
}
