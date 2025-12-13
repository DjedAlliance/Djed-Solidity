// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

/**
 * @title DeploymentParametersTefnut
 * @notice Configuration management for DjedTefnut deployment across different chains
 * @dev Returns deployment parameters based on chain ID
 */
contract DeploymentParametersTefnut {
    
    /// @notice Struct containing all DjedTefnut constructor parameters
    struct Parameters {
        address oracleAddress;      // Oracle contract address (address(0) signals mock needed)
        uint256 scalingFactor;      // Scaling factor for decimal representation
        address treasury;           // Treasury address for fee collection
        uint256 treasuryFee;        // Fixed treasury fee (no decay)
        uint256 fee;                // Protocol fee
        uint256 thresholdSupplySc;  // Threshold supply for stable coins
        uint256 rcMinPrice;         // Minimum reserve coin price
        uint256 rcInitialPrice;     // Initial reserve coin price
        uint256 txLimit;            // Transaction limit
    }

    // Chain IDs
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ANVIL_CHAIN_ID = 31337;

    // Known oracle addresses
    address constant SEPOLIA_SHU_ORACLE_ADDRESS = address(0); // Placeholder - replace with actual address when deployed

    // Known treasury addresses
    address constant SEPOLIA_TREASURY = 0x0f5342B55ABCC0cC78bdB4868375bCA62B6c16eA;
    address constant LOCAL_TREASURY = 0x078D888E40faAe0f32594342c85940AF3949E666;

    /**
     * @notice Get deployment parameters for a specific chain
     * @param chainId The chain ID to get parameters for
     * @return params The Parameters struct with all constructor arguments
     */
    function getParams(uint256 chainId) public pure returns (Parameters memory params) {
        if (chainId == SEPOLIA_CHAIN_ID) {
            // Sepolia Testnet Configuration
            params = Parameters({
                oracleAddress: SEPOLIA_SHU_ORACLE_ADDRESS,  // Will be replaced with actual address
                scalingFactor: 1e24,
                treasury: SEPOLIA_TREASURY,
                treasuryFee: 25e20,                         // 0.25%
                fee: 15e21,                                 // 1.5%
                thresholdSupplySc: 5e11,                    // 500k SC
                rcMinPrice: 1e18,                           // 1 ETH per RC
                rcInitialPrice: 1e20,                       // 100 ETH per RC
                txLimit: 1e10                               // 10k SC
            });
        } else {
            // Local/Anvil Default Configuration
            // oracleAddress = address(0) signals that a mock oracle should be deployed
            params = Parameters({
                oracleAddress: address(0),                  // Signal to deploy mock
                scalingFactor: 1e24,
                treasury: LOCAL_TREASURY,
                treasuryFee: 0,                             // 0% for testing
                fee: 15e21,                                 // 1.5%
                thresholdSupplySc: 1e6,                     // 1M SC
                rcMinPrice: 1e18,                           // 1 ETH per RC
                rcInitialPrice: 1e20,                       // 100 ETH per RC
                txLimit: 200e6                              // 200 SC
            });
        }
    }

    /**
     * @notice Get human-readable network name
     * @param chainId The chain ID
     * @return name The network name
     */
    function getNetworkName(uint256 chainId) public pure returns (string memory name) {
        if (chainId == SEPOLIA_CHAIN_ID) {
            return "Ethereum Sepolia";
        } else if (chainId == ANVIL_CHAIN_ID) {
            return "Anvil Local";
        } else {
            return "Unknown Network";
        }
    }
}
