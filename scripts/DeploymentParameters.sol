// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract DeploymentParameters {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA,
        MILKOMEDA_TESTNET,
        ETHEREUM_CLASSIC_MORDOR,
        ETHEREUM_CLASSIC_MAINNET
    }

    enum SupportedVersion {
        DJED,
        DJED_SHU
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
    address constant HEBESWAP_ORACLE_INVERTED_ADDRESS_MORDOR = 0xb0d99da21Bb4fa877e3D1DCA89E6657c5e840Eb2;
    address constant HEBESWAP_ORACLE_INVERTED_ADDRESS_MAINNET = 0x2fd961e20896e121EC7D499cC4F38462e286994A;
    address constant HEBESWAP_SHU_ORACLE_INVERTED_ADDRESS_MORDOR = 0x8Bd4A5F6a4727Aa4AC05f8784aACAbE2617e860A;
    
    address oracleAddress;
    address treasuryAddress;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.MILKOMEDA_TESTNET] = "Milkomeda C1 Testnet";
        networks[SupportedNetworks.ETHEREUM_CLASSIC_MORDOR] = "Ethereum Classic Mordor";
        networks[SupportedNetworks.ETHEREUM_CLASSIC_MAINNET] = "Ethereum Classic Mainnet";
    }

    function getConfigFromNetwork(
        SupportedNetworks network,
        SupportedVersion version
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
            SCALING_FACTOR=1e24;
            INITIAL_TREASURY_FEE=25e20;
            TREASURY_REVENUE_TARGET=1e25;
            RESERVE_RATIO_MIN=4e24;
            RESERVE_RATIO_MAX=8e24;
            FEE=15e21;
            THREASHOLD_SUPPLY_SC=5e11;
            RESERVE_COIN_MINIMUM_PRICE=1e18;
            RESERVE_COIN_INITIAL_PRICE=1e20;
            TX_LIMIT=1e10;


        }

        if (network == SupportedNetworks.ETHEREUM_CLASSIC_MORDOR) {
            oracleAddress = version == SupportedVersion.DJED_SHU ? HEBESWAP_SHU_ORACLE_INVERTED_ADDRESS_MORDOR : HEBESWAP_ORACLE_INVERTED_ADDRESS_MORDOR;
            treasuryAddress = 0xBC80a858F6F9116aA2dc549325d7791432b6c6C4;
            SCALING_FACTOR=1e24;
            INITIAL_TREASURY_FEE=25e20;
            TREASURY_REVENUE_TARGET=21700000e18;
            RESERVE_RATIO_MIN=3e24;
            RESERVE_RATIO_MAX=8e24;
            FEE=12500e18;
            THREASHOLD_SUPPLY_SC=10e6;
            RESERVE_COIN_MINIMUM_PRICE=1e15;
            RESERVE_COIN_INITIAL_PRICE=1e18;
            TX_LIMIT=1e10;
        }

        if (network == SupportedNetworks.ETHEREUM_CLASSIC_MAINNET) {
            oracleAddress = HEBESWAP_ORACLE_INVERTED_ADDRESS_MAINNET;
            treasuryAddress = 0xBC80a858F6F9116aA2dc549325d7791432b6c6C4;
            SCALING_FACTOR=1e24;
            INITIAL_TREASURY_FEE=25e20;
            TREASURY_REVENUE_TARGET=21700000e18;
            RESERVE_RATIO_MIN=3e24;
            RESERVE_RATIO_MAX=8e24;
            FEE=12500e18;
            THREASHOLD_SUPPLY_SC=10e6;
            RESERVE_COIN_MINIMUM_PRICE=1e15;
            RESERVE_COIN_INITIAL_PRICE=1e18;
            TX_LIMIT=1e10;
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
