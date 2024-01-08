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

    address chainlinkOracle;
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
            chainlinkOracle = 0x7609Da7a13b5feD98d5D79463dA6C7a57d1E8a84;
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


        } else if (network == SupportedNetworks.MILKOMEDA_TESTNET) {
            chainlinkOracle = 0x0000000000000000000000000000000000000000;
            treasuryAddress = 0x3AA00B7aCF12CbcA5044d11E588E7fb1a5aa5A84;
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
            chainlinkOracle,
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
