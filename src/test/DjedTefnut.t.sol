// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";
import "../DjedTefnut.sol";
import "../mock/MockShuOracle.sol";
import "./Utilities.sol";

contract DjedTefnutTest is CTest, Utilities {
    MockShuOracle private oracle;
    DjedTefnut private djed;
    CheatCodes private cheats = CheatCodes(HEVM_ADDRESS);


    // Tefnut-specific parameters (no reserve ratio constraints)
    uint256 constant TEFNUT_SCALING_FACTOR = 1e24;
    uint256 constant TEFNUT_INITIAL_BALANCE = 1e18; // 1 ETH
    uint256 constant TEFNUT_FEE = (1 * TEFNUT_SCALING_FACTOR) / 100; // 1%
    uint256 constant TEFNUT_INITIAL_TREASURY_FEE = 25e20; // 25%
    uint256 constant TEFNUT_THRESHOLD_SUPPLY_SC = 5e11;
    uint256 constant TEFNUT_RC_MIN_PRICE = 1e18;
    uint256 constant TEFNUT_RC_INITIAL_PRICE = 1e20;
    uint256 constant TEFNUT_TX_LIMIT = 1e10;


    function setUp() public {
        oracle = new MockShuOracle(ORACLE_EXCHANGE_RATE);
        djed = (new DjedTefnut){value: TEFNUT_INITIAL_BALANCE}(
            address(oracle),
            TEFNUT_SCALING_FACTOR,
            TREASURY,
            TEFNUT_INITIAL_TREASURY_FEE,
            TEFNUT_FEE,
            TEFNUT_THRESHOLD_SUPPLY_SC,
            TEFNUT_RC_MIN_PRICE,
            TEFNUT_RC_INITIAL_PRICE,
            TEFNUT_TX_LIMIT
        );
        cheats.deal(account1, 100 ether);
        cheats.deal(account2, 100 ether);

        // Verify Tefnut parameters (no reserve ratio constraints to verify)
        assertTrue(TEFNUT_FEE > 0 && TEFNUT_SCALING_FACTOR >= TEFNUT_FEE);
        assertTrue(TEFNUT_THRESHOLD_SUPPLY_SC > 0);
        assertTrue(TEFNUT_RC_MIN_PRICE > 0);
        assertTrue(ORACLE_EXCHANGE_RATE > 0);
    }


    // Test that sellBothCoins function does not exist
    function testSellBothCoinsDoesNotExist() public {
        // This test verifies that sellBothCoins function was properly removed
        // by checking the contract bytecode doesn't contain the function selector
        bytes4 selector = bytes4(keccak256("sellBothCoins(uint256,uint256,address,uint256,address)"));
        bytes memory code = address(djed).code;
        assertTrue(!containsSelector(code, selector), "sellBothCoins function should not exist in DjedTefnut");
    }

    // Test that reserve ratio functions do not exist
    function testReserveRatioFunctionsDoNotExist() public {
        bytes4 ratioMaxSelector = bytes4(keccak256("ratioMax()"));
        bytes4 ratioMinSelector = bytes4(keccak256("ratioMin()"));
        bytes4 isRatioAboveMinSelector = bytes4(keccak256("isRatioAboveMin(uint256)"));
        bytes4 isRatioBelowMaxSelector = bytes4(keccak256("isRatioBelowMax(uint256)"));

        bytes memory code = address(djed).code;
        assertTrue(!containsSelector(code, ratioMaxSelector), "ratioMax should not exist");
        assertTrue(!containsSelector(code, ratioMinSelector), "ratioMin should not exist");
        assertTrue(!containsSelector(code, isRatioAboveMinSelector), "isRatioAboveMin should not exist");
        assertTrue(!containsSelector(code, isRatioBelowMaxSelector), "isRatioBelowMax should not exist");
    }

    // Helper function to check if a selector exists in contract bytecode
    function containsSelector(bytes memory code, bytes4 selector) internal pure returns (bool) {
        for (uint i = 0; i <= code.length - 4; i++) {
            if (code[i] == selector[0] && code[i+1] == selector[1] && code[i+2] == selector[2] && code[i+3] == selector[3]) {
                return true;
            }
        }
        return false;
    }


    // Test treasury fee is constant (not decaying)
    function testTreasuryFeeIsConstant() public {
        uint256 initialFee = djed.treasuryFee();
        assertEq(initialFee, TEFNUT_INITIAL_TREASURY_FEE);

        // Perform some transactions to trigger treasury fee collection
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0));

        // Fee should remain constant despite treasury revenue
        uint256 feeAfter = djed.treasuryFee();
        assertEq(feeAfter, TEFNUT_INITIAL_TREASURY_FEE);
    }


    function testInitialBalance() public {
        assertEq(R(djed), TEFNUT_INITIAL_BALANCE);
    }

    function testBuyStableCoins() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0));
        
        // Verify stable coins were minted
        assertTrue(djed.stableCoin().balanceOf(account1) > 0);
        assertTrue(djed.stableCoin().totalSupply() > 0);
        assertEq(djed.reserveCoin().totalSupply(), 0);
        assertEq(R(djed), 2e18); // 2 ETH total
    }

    function testSellStableCoins() public {
        // First buy some stable coins
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0));
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        assertTrue(scBalance > 0);

        // Then sell them back
        cheats.prank(account1);
        djed.sellStableCoins(scBalance, account1, 0, address(0));
        
        // Verify stable coins were burned
        assertEq(djed.stableCoin().balanceOf(account1), 0);
        assertEq(djed.stableCoin().totalSupply(), 0);
    }

    function testBuyReserveCoins() public {
        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e18}(account1, 0, address(0));
        
        // Verify reserve coins were minted
        assertTrue(djed.reserveCoin().balanceOf(account1) > 0);
        assertTrue(djed.reserveCoin().totalSupply() > 0);
        assertEq(djed.stableCoin().totalSupply(), 0);
        assertEq(R(djed), 2e18); // 2 ETH total
    }

    function testSellReserveCoins() public {
        // First buy some reserve coins
        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e18}(account1, 0, address(0));
        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);
        assertTrue(rcBalance > 0);

        // Then sell them back
        cheats.prank(account1);
        djed.sellReserveCoins(rcBalance, account1, 0, address(0));
        
        // Verify reserve coins were burned
        assertEq(djed.reserveCoin().balanceOf(account1), 0);
        assertEq(djed.reserveCoin().totalSupply(), 0);
    }

    // Test that reserve ratio constraints are removed - should be able to buy regardless of ratio
    function testBuyReserveCoinsWithoutRatioConstraints() public {
        // Buy a large amount of stable coins to create high ratio
        cheats.prank(account1);
        djed.buyStableCoins{value: 100e18}(account1, 0, address(0));
        
        // Should still be able to buy reserve coins without ratio constraint
        // In DjedShu this would fail with "buyRC: ratio above max"
        cheats.prank(account2);
        djed.buyReserveCoins{value: 1e18}(account2, 0, address(0));
        
        assertTrue(djed.reserveCoin().balanceOf(account2) > 0);
    }

    function testBuyStableCoinsWithoutRatioConstraints() public {
        // First create some reserve coins to establish a ratio
        cheats.prank(account1);
        djed.buyReserveCoins{value: 10e18}(account1, 0, address(0));
        
        // Should still be able to buy stable coins without ratio constraint
        // In DjedShu this might fail with "buySC: ratio below min"
        cheats.prank(account2);
        djed.buyStableCoins{value: 1e18}(account2, 0, address(0));
        
        assertTrue(djed.stableCoin().balanceOf(account2) > 0);
    }

    // Test dual-oracle functionality
    function testDualOraclePrices() public {
        // Set oracle prices
        oracle.increasePrice(); // Increase max price
        oracle.decreasePrice(); // Decrease min price
        
        uint256 maxPrice = djed.scMaxPrice(0);
        uint256 minPrice = djed.scMinPrice(0);
        
        // Max price should be >= min price
        assertTrue(maxPrice >= minPrice);
    }


    // Test that treasury fee calculation works correctly
    function testTreasuryFeeCalculation() public {
        // Perform a transaction
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0));
        
        // Treasury fee should be constant
        uint256 treasuryFee = djed.treasuryFee();
        assertEq(treasuryFee, TEFNUT_INITIAL_TREASURY_FEE);
    }



    // Override R function for DjedTefnut
    function R(DjedTefnut c) internal view returns (uint256) {
        return address(c).balance;
    }
}
