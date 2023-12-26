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

    // Chainlink Oracle addresses
    address constant chainlinkOracleEthereumSepolia =
        0x7609Da7a13b5feD98d5D79463dA6C7a57d1E8a84;
    address constant chainlinkOracleMilkomedaTestnet =
        0x0000000000000000000000000000000000000000;

    // Chainlink Oracle addresses
    address constant chainlinkDataFeedEthereumSepolia =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant chainlinkDataFeedMilkomedaTestnet =
        0x0000000000000000000000000000000000000000;

    // Treasury addresses
    address constant treasuryAddressEthereumSepolia =
        0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA;
    address constant treasuryAddressMilkomedaTestnet =
        0x3AA00B7aCF12CbcA5044d11E588E7fb1a5aa5A84;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.MILKOMEDA_TESTNET] = "Milkomeda C1 Testnet";
    }

    // function getConstantValues(

    // )
    //     internal
    //     pure
    //     returns (
    //         uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    //     )
    // {
    //     return (
    //         DJED_DECIMALS,
    //         SCALING_FACTOR,
    //         INITIAL_TREASURY_FEE,
    //         TREASURY_REVENUE_TARGET,
    //         RESERVE_RATIO_MIN,
    //         RESERVE_RATIO_MAX,
    //         FEE,
    //         THREASHOLD_SUPPLY_SC,
    //         RESERVE_COIN_MINIMUM_PRICE,
    //         RESERVE_COIN_INITIAL_PRICE,
    //         TX_LIMIT
    //     );
    // }

    function getConfigFromNetwork(
        SupportedNetworks network
    )
        internal
        pure
        returns (
            address chainlinkOracle,
            address chainlinkDataFeed,
            address treasuryAddress
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (
                chainlinkOracleEthereumSepolia,
                chainlinkDataFeedEthereumSepolia,
                treasuryAddressEthereumSepolia
            );
        } else if (network == SupportedNetworks.MILKOMEDA_TESTNET) {
            return (
                chainlinkOracleMilkomedaTestnet,
                chainlinkDataFeedMilkomedaTestnet,
                treasuryAddressMilkomedaTestnet
            );
        } 
    }
}
