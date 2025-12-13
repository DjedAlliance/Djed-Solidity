// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "./DeploymentParametersTefnut.sol";
import {DjedTefnut} from "../src/DjedTefnut.sol";
import {MockShuOracleTefnut} from "../src/mock/MockShuOracleTefnut.sol";

/**
 * @title DeployDjedTefnut
 * @notice Deployment script for DjedTefnut contract
 * @dev Automatically deploys mock oracle for local/test chains
 * 
 * Usage:
 *   Local (Anvil): forge script scripts/deployDjedTefnutContract.s.sol --broadcast --rpc-url http://127.0.0.1:8545
 *   Sepolia: forge script scripts/deployDjedTefnutContract.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL
 */
contract DeployDjedTefnut is Script, DeploymentParametersTefnut {
    
    // Default oracle exchange rate: 1 USD = 0.5 ETH (in weis per whole SC)
    uint256 constant DEFAULT_ORACLE_PRICE = 5e17;
    
    // Initial balance to seed the contract
    uint256 constant INITIAL_BALANCE = 1e18; // 1 ETH

    function run() external {
        // Get deployment parameters based on current chain
        Parameters memory params = getParams(block.chainid);
        
        console.log("===========================================");
        console.log("Deploying DjedTefnut");
        console.log("Network:", getNetworkName(block.chainid));
        console.log("Chain ID:", block.chainid);
        console.log("===========================================");

        // Start broadcasting transactions
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Dynamic Mocking: Deploy mock oracle if oracleAddress is address(0)
        if (params.oracleAddress == address(0)) {
            console.log("");
            console.log("Oracle address is zero - deploying MockShuOracleTefnut...");
            
            MockShuOracleTefnut mockOracle = new MockShuOracleTefnut(DEFAULT_ORACLE_PRICE);
            params.oracleAddress = address(mockOracle);
            
            console.log("MockShuOracleTefnut deployed at:", address(mockOracle));
            console.log("Initial oracle price:", DEFAULT_ORACLE_PRICE);
        }

        // Log deployment parameters
        console.log("");
        console.log("Deployment Parameters:");
        console.log("  Oracle Address:", params.oracleAddress);
        console.log("  Scaling Factor:", params.scalingFactor);
        console.log("  Treasury:", params.treasury);
        console.log("  Treasury Fee:", params.treasuryFee);
        console.log("  Fee:", params.fee);
        console.log("  Threshold Supply SC:", params.thresholdSupplySc);
        console.log("  RC Min Price:", params.rcMinPrice);
        console.log("  RC Initial Price:", params.rcInitialPrice);
        console.log("  TX Limit:", params.txLimit);

        // Deploy DjedTefnut with the (potentially updated) parameters
        DjedTefnut djedTefnut = new DjedTefnut{value: INITIAL_BALANCE}(
            params.oracleAddress,
            params.scalingFactor,
            params.treasury,
            params.treasuryFee,
            params.fee,
            params.thresholdSupplySc,
            params.rcMinPrice,
            params.rcInitialPrice,
            params.txLimit
        );

        console.log("");
        console.log("===========================================");
        console.log("DjedTefnut deployed at:", address(djedTefnut));
        console.log("StableCoin deployed at:", address(djedTefnut.stableCoin()));
        console.log("ReserveCoin deployed at:", address(djedTefnut.reserveCoin()));
        console.log("Initial Reserve:", address(djedTefnut).balance);
        console.log("===========================================");

        vm.stopBroadcast();
    }
}
