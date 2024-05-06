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

    address constant CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS = 0xB9C050Fd340aD5ED3093F31aAFAcC3D779f405f4;
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
            address, address, 
            uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            oracleAddress = CHAINLINK_SEPOLIA_INVERTED_ORACLE_ADDRESS;
            treasuryAddress = 0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA;
            SCALING_FACTOR=1000000000000000000000000;
            INITIAL_TREASURY_FEE=2500000000000000000000;
            TREASURY_REVENUE_TARGET=10000000000000000000000000;
            RESERVE_RATIO_MIN=4000000000000000000000000;
            RESERVE_RATIO_MAX=8000000000000000000000000;
            FEE=15000000000000000000000;
            THREASHOLD_SUPPLY_SC=500000000000;
            RESERVE_COIN_MINIMUM_PRICE=1000000000000000000;
            RESERVE_COIN_INITIAL_PRICE=100000000000000000000;
            TX_LIMIT=10000000000;


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
