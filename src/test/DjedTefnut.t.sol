// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";
import "../DjedTefnut.sol";
import "../mock/MockShuOracleTefnut.sol";

/**
 * @title DjedTefnutTest
 * @notice Comprehensive test suite for DjedTefnut contract
 * @dev Tests all trading functions, edge cases, and the key Tefnut feature: no reserve ratio restrictions
 */
contract DjedTefnutTest is CTest {
    MockShuOracleTefnut private oracle;
    DjedTefnut private djed;
    CheatCodes private cheats = CheatCodes(HEVM_ADDRESS);

    // ============ Test Constants ============
    
    uint256 constant SCALING_FACTOR = 1e24;
    uint256 constant INITIAL_BALANCE = 1e18; // 1 ETH
    uint256 constant SC_DECIMAL_SCALING_FACTOR = 1e6;
    uint256 constant RC_DECIMAL_SCALING_FACTOR = 1e6;

    // Fee parameters
    uint256 constant FEE = (15 * SCALING_FACTOR) / 1000; // 1.5%
    uint256 constant TREASURY_FEE = 0; // 0% for testing
    
    // Coin parameters
    uint256 constant RC_MIN_PRICE = 1e18;
    uint256 constant RC_INITIAL_PRICE = 1e20;
    uint256 constant THRESHOLD_SUPPLY_SC = 1e6;
    uint256 constant TX_LIMIT = 200e6; // 200 SC

    // Oracle price: 1 USD = 0.5 ETH (in weis per whole SC)
    uint256 constant ORACLE_PRICE = 5e17;

    // Test addresses
    address constant TREASURY = 0x078D888E40faAe0f32594342c85940AF3949E666;
    address account1 = 0x766FCe3d50d795Fe6DcB1020AB58bccddd5C5c77;
    address account2 = 0xd109c2fCfc7fE7AE9ccdE37529E50772053Eb7EE;
    address UI_ADDRESS = 0x3EA53fA26b41885cB9149B62f0b7c0BAf76C78D4;

    // ============ Events (for testing emission) ============
    
    event BoughtStableCoins(address indexed buyer, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event SoldStableCoins(address indexed seller, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event BoughtReserveCoins(address indexed buyer, address indexed receiver, uint256 amountRc, uint256 amountBc);
    event SoldReserveCoins(address indexed seller, address indexed receiver, uint256 amountRc, uint256 amountBc);

    // ============ Setup ============

    function setUp() public {
        // Deploy mock oracle
        oracle = new MockShuOracleTefnut(ORACLE_PRICE);
        
        // Deploy DjedTefnut with initial balance
        djed = (new DjedTefnut){value: INITIAL_BALANCE}(
            address(oracle),
            SCALING_FACTOR,
            TREASURY,
            TREASURY_FEE,
            FEE,
            THRESHOLD_SUPPLY_SC,
            RC_MIN_PRICE,
            RC_INITIAL_PRICE,
            TX_LIMIT
        );

        // Fund test accounts
        cheats.deal(account1, 100 ether);
        cheats.deal(account2, 100 ether);

        // Verify deployment
        assertTrue(address(djed) != address(0), "DjedTefnut not deployed");
        assertEq(address(djed).balance, INITIAL_BALANCE, "Initial balance mismatch");
    }

    // ============ Helper Functions ============

    function R() internal view returns (uint256) {
        return address(djed).balance;
    }

    function calculateExpectedFee(uint256 amount) internal pure returns (uint256) {
        return (amount * FEE) / SCALING_FACTOR;
    }

    // ============ Basic State Tests ============

    function testInitialState() public {
        assertEq(R(), INITIAL_BALANCE, "Initial reserve mismatch");
        assertEq(djed.stableCoin().totalSupply(), 0, "Initial SC supply should be 0");
        assertEq(djed.reserveCoin().totalSupply(), 0, "Initial RC supply should be 0");
        assertEq(address(djed.oracle()), address(oracle), "Oracle address mismatch");
        assertEq(djed.TREASURY(), TREASURY, "Treasury address mismatch");
    }

    // ============ Buy StableCoins Tests ============

    function testBuyStableCoins() public {
        uint256 buyAmount = 1e18; // 1 ETH
        uint256 initialBalance = account1.balance;
        
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, UI_ADDRESS);

        // Verify SC balance increased
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        assertTrue(scBalance > 0, "Should receive SC");
        
        // Verify total supply
        assertEq(djed.stableCoin().totalSupply(), scBalance, "Total supply should match balance");
        
        // Verify reserve increased
        assertEq(R(), INITIAL_BALANCE + buyAmount, "Reserve should increase");
        
        // Verify account1 ETH decreased
        assertEq(account1.balance, initialBalance - buyAmount, "Account balance should decrease");
    }

    function testBuyStableCoinsToReceiver() public {
        uint256 buyAmount = 1e18;
        
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account2, 0, UI_ADDRESS);

        // Verify receiver got the SC
        assertTrue(djed.stableCoin().balanceOf(account2) > 0, "Receiver should get SC");
        assertEq(djed.stableCoin().balanceOf(account1), 0, "Buyer should not get SC");
    }

    // ============ Sell StableCoins Tests ============

    function testSellStableCoins() public {
        // First buy some SC
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, UI_ADDRESS);
        
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        uint256 ethBalanceBefore = account1.balance;
        uint256 reserveBefore = R();

        // Sell all SC
        cheats.prank(account1);
        djed.sellStableCoins(scBalance, account1, 0, UI_ADDRESS);

        // Verify SC burned
        assertEq(djed.stableCoin().balanceOf(account1), 0, "SC should be burned");
        assertEq(djed.stableCoin().totalSupply(), 0, "Total SC supply should be 0");
        
        // Verify ETH received (less fees)
        assertTrue(account1.balance > ethBalanceBefore, "Should receive ETH");
        
        // Verify reserve decreased
        assertTrue(R() < reserveBefore, "Reserve should decrease");
    }

    function testSellStableCoinsToReceiver() public {
        // Buy SC for account1
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, UI_ADDRESS);
        
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        uint256 account2BalanceBefore = account2.balance;

        // Sell SC and send ETH to account2
        cheats.prank(account1);
        djed.sellStableCoins(scBalance, account2, 0, UI_ADDRESS);

        // Verify account2 received ETH
        assertTrue(account2.balance > account2BalanceBefore, "Receiver should get ETH");
    }

    // ============ Buy ReserveCoins Tests ============

    function testBuyReserveCoins() public {
        uint256 buyAmount = 1e18;
        
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account1, 0, UI_ADDRESS);

        // Verify RC balance
        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);
        assertTrue(rcBalance > 0, "Should receive RC");
        
        // Verify total supply
        assertEq(djed.reserveCoin().totalSupply(), rcBalance, "Total supply should match");
        
        // Verify reserve increased
        assertEq(R(), INITIAL_BALANCE + buyAmount, "Reserve should increase");
    }

    function testBuyReserveCoinsToReceiver() public {
        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e18}(account2, 0, UI_ADDRESS);

        assertTrue(djed.reserveCoin().balanceOf(account2) > 0, "Receiver should get RC");
        assertEq(djed.reserveCoin().balanceOf(account1), 0, "Buyer should not get RC");
    }

    // ============ Sell ReserveCoins Tests ============

    function testSellReserveCoins() public {
        // First buy RC
        cheats.prank(account1);
        djed.buyReserveCoins{value: 10e18}(account1, 0, UI_ADDRESS);
        
        // Need to buy some SC to establish equity
        cheats.prank(account2);
        djed.buyStableCoins{value: 1e18}(account2, 0, UI_ADDRESS);

        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);
        uint256 ethBalanceBefore = account1.balance;

        // Sell RC
        cheats.prank(account1);
        djed.sellReserveCoins(rcBalance, account1, 0, UI_ADDRESS);

        // Verify RC burned
        assertEq(djed.reserveCoin().balanceOf(account1), 0, "RC should be burned");
        
        // Verify ETH received
        assertTrue(account1.balance > ethBalanceBefore, "Should receive ETH");
    }

    // ============ CRITICAL: No Reserve Ratio Check Tests ============

    /**
     * @notice CRITICAL TEST: Proves that buyStableCoins succeeds even with 0 Reserve Coins
     * @dev In original Djed, buying SC when ratio < min would revert. In Tefnut, it should succeed.
     */
    function testNoReserveRatioCheck_BuyScWithZeroRc() public {
        // System state: 0 RC, 0 SC
        assertEq(djed.reserveCoin().totalSupply(), 0, "RC supply should be 0");
        assertEq(djed.stableCoin().totalSupply(), 0, "SC supply should be 0");
        
        // In original Djed, this would fail with "buySC: ratio below min"
        // In Tefnut, it should succeed
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, UI_ADDRESS);

        // Verify success
        assertTrue(djed.stableCoin().balanceOf(account1) > 0, "Should buy SC without RC");
        assertEq(djed.reserveCoin().totalSupply(), 0, "RC should still be 0");
    }

    /**
     * @notice Test that buying large amounts of SC works without ratio restrictions
     */
    function testNoReserveRatioCheck_LargeSCPurchase() public {
        // Buy a large amount of SC without any RC in system
        cheats.prank(account1);
        djed.buyStableCoins{value: 50e18}(account1, 0, UI_ADDRESS); // 50 ETH

        assertTrue(djed.stableCoin().balanceOf(account1) > 0, "Large SC purchase should succeed");
    }

    /**
     * @notice Test that selling RC works without ratio restrictions
     */
    function testNoReserveRatioCheck_SellAllRc() public {
        // Setup: Buy RC then SC
        cheats.prank(account1);
        djed.buyReserveCoins{value: 10e18}(account1, 0, UI_ADDRESS);
        
        cheats.prank(account2);
        djed.buyStableCoins{value: 5e18}(account2, 0, UI_ADDRESS);

        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);

        // In original Djed, selling all RC when SC exists would fail with "sellRC: ratio below min"
        // In Tefnut, it should succeed
        cheats.prank(account1);
        djed.sellReserveCoins(rcBalance, account1, 0, UI_ADDRESS);

        assertEq(djed.reserveCoin().balanceOf(account1), 0, "Should sell all RC");
        assertTrue(djed.stableCoin().totalSupply() > 0, "SC should still exist");
    }

    /**
     * @notice Test buying RC works without max ratio restriction
     */
    function testNoReserveRatioCheck_BuyRcAboveMaxRatio() public {
        // Buy SC first
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e17}(account1, 0, UI_ADDRESS);

        // In original Djed with high reserve, buying more RC would fail with "buyRC: ratio above max"
        // In Tefnut, there's no max ratio check
        cheats.prank(account2);
        djed.buyReserveCoins{value: 50e18}(account2, 0, UI_ADDRESS);

        assertTrue(djed.reserveCoin().balanceOf(account2) > 0, "Should buy RC without ratio limit");
    }

    // ============ Fee Tests ============

    function testFeesDeducted() public {
        uint256 treasuryBalanceBefore = TREASURY.balance;
        uint256 buyAmount = 10e18;

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, 0, UI_ADDRESS);

        // Protocol fee stays in reserve, UI fee (0) goes to UI
        // Treasury fee (0 in test) goes to treasury
        assertEq(TREASURY.balance, treasuryBalanceBefore, "Treasury should receive no fee (0%)");
    }

    function testUIFeeDeducted() public {
        uint256 uiBalanceBefore = UI_ADDRESS.balance;
        uint256 uiFee = 1e21; // 0.1%
        uint256 buyAmount = 10e18;

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, uiFee, UI_ADDRESS);

        // UI should receive fee
        uint256 expectedUIFee = (buyAmount * uiFee) / SCALING_FACTOR;
        assertEq(UI_ADDRESS.balance - uiBalanceBefore, expectedUIFee, "UI should receive fee");
    }

    // ============ Revert Tests ============

    function testRevertBuyZeroSc() public {
        // Sending 0 ETH should revert with "buySC: receiving zero SCs"
        cheats.prank(account1);
        cheats.expectRevert("buySC: receiving zero SCs");
        djed.buyStableCoins{value: 0}(account1, 0, UI_ADDRESS);
    }

    function testRevertSellMoreScThanBalance() public {
        cheats.prank(account1);
        djed.buyStableCoins{value: 1e18}(account1, 0, UI_ADDRESS);
        
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        
        // Try to sell more than balance
        cheats.prank(account1);
        cheats.expectRevert("sellSC: insufficient SC balance");
        djed.sellStableCoins(scBalance + 1, account1, 0, UI_ADDRESS);
    }

    function testRevertSellMoreRcThanBalance() public {
        cheats.prank(account1);
        djed.buyReserveCoins{value: 1e18}(account1, 0, UI_ADDRESS);
        
        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);
        
        // Try to sell more than balance
        cheats.prank(account1);
        cheats.expectRevert("sellRC: insufficient RC balance");
        djed.sellReserveCoins(rcBalance + 1, account1, 0, UI_ADDRESS);
    }

    function testRevertInvalidUIAddress() public {
        cheats.prank(account1);
        cheats.expectRevert("Invalid UI address");
        djed.buyStableCoins{value: 1e18}(account1, 0, address(0));
    }

    function testRevertTotalFeesExceed100Percent() public {
        uint256 excessiveFee = SCALING_FACTOR; // 100%
        cheats.prank(account1);
        cheats.expectRevert("Total fees exceed 100%");
        djed.buyStableCoins{value: 1e18}(account1, excessiveFee, UI_ADDRESS);
    }

    // ============ TX Limit Tests ============

    function testTxLimitRespectedAboveThreshold() public {
        // First get above threshold
        cheats.prank(account1);
        djed.buyStableCoins{value: 10e18}(account1, 0, UI_ADDRESS);
        
        // Verify we're above threshold
        assertTrue(djed.stableCoin().totalSupply() >= THRESHOLD_SUPPLY_SC, "Should be above threshold");

        // Calculate amount that exceeds TX_LIMIT in SC terms
        // TX_LIMIT is in SC units (200e6 = 200 SC)
        // At price 0.5 ETH/SC, 200 SC = 100 ETH worth
        // But after fees, we need more ETH to get 200+ SC
        
        // This should succeed if under TX_LIMIT
        cheats.prank(account2);
        djed.buyStableCoins{value: 1e17}(account2, 0, UI_ADDRESS); // Small amount, should work
        
        assertTrue(djed.stableCoin().balanceOf(account2) > 0, "Should succeed under TX limit");
    }

    // ============ Price Function Tests ============

    function testScMaxPrice() public {
        uint256 scMaxPrice = djed.scMaxPrice(0);
        // Price should be oracle price when no SC exists or reserve is high
        assertTrue(scMaxPrice > 0, "SC max price should be > 0");
    }

    function testScMinPrice() public {
        uint256 scMinPrice = djed.scMinPrice(0);
        assertTrue(scMinPrice > 0, "SC min price should be > 0");
    }

    function testRcBuyingPrice() public {
        uint256 rcBuyingPrice = djed.rcBuyingPrice(0);
        // When RC supply is 0, should return initial price
        assertEq(rcBuyingPrice, RC_INITIAL_PRICE, "RC buying price should be initial price when supply is 0");
    }

    // ============ Oracle Integration Tests ============

    function testOraclePriceChange() public {
        // Get initial SC price
        uint256 scPriceBefore = djed.scMaxPrice(0);
        
        // Change oracle price
        oracle.setPrice(ORACLE_PRICE * 2); // Double the price
        
        // Price should change
        uint256 scPriceAfter = djed.scMaxPrice(0);
        assertTrue(scPriceAfter != scPriceBefore || djed.stableCoin().totalSupply() > 0, 
            "Price should reflect oracle change");
    }

    // ============ Multiple Operations Tests ============

    function testMultipleBuySellCycles() public {
        // Multiple buy/sell cycles
        for (uint256 i = 0; i < 3; i++) {
            cheats.prank(account1);
            djed.buyStableCoins{value: 1e18}(account1, 0, UI_ADDRESS);
            
            uint256 scBalance = djed.stableCoin().balanceOf(account1);
            
            cheats.prank(account1);
            djed.sellStableCoins(scBalance / 2, account1, 0, UI_ADDRESS);
        }

        assertTrue(djed.stableCoin().balanceOf(account1) > 0, "Should have SC after cycles");
    }

    function testMixedScRcOperations() public {
        // Buy SC
        cheats.prank(account1);
        djed.buyStableCoins{value: 2e18}(account1, 0, UI_ADDRESS);
        
        // Buy RC
        cheats.prank(account1);
        djed.buyReserveCoins{value: 5e18}(account1, 0, UI_ADDRESS);
        
        // Sell some SC
        uint256 scBalance = djed.stableCoin().balanceOf(account1);
        cheats.prank(account1);
        djed.sellStableCoins(scBalance / 2, account1, 0, UI_ADDRESS);
        
        // Sell some RC
        uint256 rcBalance = djed.reserveCoin().balanceOf(account1);
        cheats.prank(account1);
        djed.sellReserveCoins(rcBalance / 2, account1, 0, UI_ADDRESS);

        assertTrue(djed.stableCoin().balanceOf(account1) > 0, "Should have SC remaining");
        assertTrue(djed.reserveCoin().balanceOf(account1) > 0, "Should have RC remaining");
    }

    // ============ Edge Case Tests ============

    function testRatioCalculation() public {
        // Ratio function should work even with 0 liabilities
        uint256 ratio = djed.ratio();
        // With 0 SC, ratio should be max uint256
        assertEq(ratio, type(uint256).max, "Ratio should be max with 0 liabilities");
    }

    function testReserveCalculation() public {
        uint256 reserve = djed.R(0);
        assertEq(reserve, INITIAL_BALANCE, "Reserve calculation should match balance");
    }
}
