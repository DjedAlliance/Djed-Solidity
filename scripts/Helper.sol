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

    uint256 constant public DJED_DECIMALS = 6;
    uint256 constant public SCALING_FACTOR=1000000000000000000000000;
    uint256 constant public INITIAL_TREASURY_FEE=2500000000000000000000;
    uint256 constant public TREASURY_REVENUE_TARGET=10000000000000000000000000;
    uint256 constant public RESERVE_RATIO_MIN=4000000000000000000000000;
    uint256 constant public RESERVE_RATIO_MAX=8000000000000000000000000;
    uint256 constant public FEE=15000000000000000000000;
    uint256 constant public THREASHOLD_SUPPLY_SC=500000000000;
    uint256 constant public RESERVE_COIN_MINIMUM_PRICE=1000000000000000000;
    uint256 constant public RESERVE_COIN_INITIAL_PRICE=100000000000000000000;
    uint256 constant public TX_LIMIT=10000000000;

    address chainlinkOracle;
    address chainlinkDataFeed;
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
            address, address, address
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            chainlinkOracle = 0x7609Da7a13b5feD98d5D79463dA6C7a57d1E8a84;
            chainlinkDataFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
            treasuryAddress = 0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA;

        } else if (network == SupportedNetworks.MILKOMEDA_TESTNET) {
            chainlinkOracle = 0x0000000000000000000000000000000000000000;
            chainlinkDataFeed = 0x0000000000000000000000000000000000000000;
            treasuryAddress = 0x3AA00B7aCF12CbcA5044d11E588E7fb1a5aa5A84;
        } 

        return (
            chainlinkOracle,
            chainlinkDataFeed,
            treasuryAddress
        );
    }
}
