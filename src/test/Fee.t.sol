// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";

import "../Djed.sol";

import "../mock/MockOracle.sol";
import "./Utilities.sol";

contract FeeTest is CTest, Utilities {
    MockOracle oracle;
    Djed djed;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        INITIAL_TREASURY_FEE = (5 * SCALING_FACTOR) / 100; // 5%
        TREASURY_REVENUE_TARGET = 6 * 1e16; // 0.06 ADA

        UI_FEE = SCALING_FACTOR / 100; // 1%

        oracle = new MockOracle(ORACLE_EXCHANGE_RATE);
        djed = (new Djed){value: INITIAL_BALANCE}(
            address(oracle),
            SCALING_FACTOR,
            TREASURY,
            INITIAL_TREASURY_FEE,
            TREASURY_REVENUE_TARGET,
            RESERVE_RATIO_MIN,
            RESERVE_RATIO_MAX,
            FEE,
            THRESHOLD_NUMBER_SC,
            RESERVE_COIN_WHOLE_MINIMUM_PRICE,
            RESERVE_COIN_WHOLE_INITIAL_PRICE,
            TX_LIMIT
        );
        cheats.deal(account1, 100 ether);
        cheats.deal(account2, 100 ether);

        // Verify Djed parameters:
        assertTrue(RESERVE_RATIO_MIN > (SCALING_FACTOR + FEE));
        assertTrue(RESERVE_RATIO_MAX >= RESERVE_RATIO_MIN);
        assertTrue((FEE > 0) && (SCALING_FACTOR >= FEE));
        assertTrue(THRESHOLD_NUMBER_SC > 0);
        assertTrue(RESERVE_COIN_WHOLE_MINIMUM_PRICE > 0);
        assertTrue(ORACLE_EXCHANGE_RATE > 0);
    }

    function testInitialBalance() public {
        assertEq(R(djed), INITIAL_BALANCE);
    }

    function testTreasuryParams() public {
        assertEq(djed.initialTreasuryFee(), INITIAL_TREASURY_FEE);
        assertTrue(djed.initialTreasuryFee() > 0);
    }

    function testBuyStableCoins() public {
        uint256 buyAmount = 1e18; // 1 ADA

        // Buying stable coin for account (account 3) different than msg.sender (account 1)
        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account3, UI_FEE, UI_DEVELOPER); // 1 ADA

        (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        ) = calculateFees(buyAmount, 0);

        uint256 nSC = 0;
        uint256 reserve = INITIAL_BALANCE;

        // expected stable coins minted
        uint256 amtReceived = amountAfterDeductionInSC(
            buyAmount,
            0,
            nSC,
            reserve
        ); // 1.86 SC

        // expected reserve
        uint256 expectedReserve = INITIAL_BALANCE +
            (buyAmount - totalFees + fee); // 1 + 0.93 ADA

        // tests
        assertTrue(djed.stableCoin().balanceOf(account1) == 0); // msg.sender should not have stable coin
        assertEq(djed.stableCoin().balanceOf(account3), amtReceived); // 1.86 SC
        assertEq(R(djed), expectedReserve); // 1.93 ADA
        assertEq(UI_DEVELOPER.balance, ui_fee); //  0.01 ADA
        assertEq(TREASURY.balance, t_fee); //  0.05 ADA
        assertEq(djed.stableCoin().totalSupply(), amtReceived); // Stable coins minted while buying above
        assertEq(djed.reserveCoin().totalSupply(), 0); // No reserve coins yet
    }

    function testSellStableCoins() public {
        uint256 currentReserve = INITIAL_BALANCE;
        uint256 uiDeveloperBalance = 0;
        uint256 treasuryBalance = 0;
        uint256 nSC = 0;

        // Buying stable coin
        cheats.prank(account1);

        // Buying for account1
        uint256 buyAmount = 1e18; // 1 ADA
        djed.buyStableCoins{value: buyAmount}(account1, UI_FEE, UI_DEVELOPER);

        uint256 amountReceived = amountAfterDeductionInSC(
            buyAmount,
            treasuryBalance,
            nSC,
            currentReserve
        ); // 1.86 SC

        (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        ) = calculateFees(buyAmount, treasuryBalance);

        uint256 amountReceivedInBC = buyAmount - totalFees; // 0.93 ADA

        // reserve will increase by (buyAmount - totalFees) and additional fee for the buying stable coin
        currentReserve += (buyAmount - totalFees);
        currentReserve += fee;
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;

        // Selling stable coin
        cheats.prank(account1);

        // Selling stable coin for account (account 3) different than msg.sender (account 1)
        djed.sellStableCoins(amountReceived, account3, UI_FEE, UI_DEVELOPER); // 1 ADA

        (fee, t_fee, ui_fee, totalFees) = calculateFees(
            amountReceivedInBC,
            treasuryBalance
        );

        // Expected base coins to be received after selling stable coins
        uint256 baseCoinReceived = amountReceivedInBC - totalFees;

        // reserve will decrease by amount debited by the buyer and increase by fee for selling stable coin
        currentReserve -= amountReceivedInBC;
        currentReserve += fee;
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;

        // tests
        assertEq(djed.stableCoin().balanceOf(account3), 0); // 0 SC
        assertEq(djed.stableCoin().totalSupply(), 0); // All stable coins are burned
        assertEq(R(djed), currentReserve); // 1 + fee
        assertEq(account3.balance, baseCoinReceived); // base coin received after selling stable coin
        assertEq(UI_DEVELOPER.balance, uiDeveloperBalance); //  0.01 + 0.093 ADA
        assertEq(TREASURY.balance, treasuryBalance); //  0.05 + 0.0465 ADA
        assertEq(djed.reserveCoin().totalSupply(), 0); // No reserve coins
    }

    function testMultipleBuyAndSellStableCoin() public {
        uint256 treasuryBalance = 0;
        uint256 nSC = 0;
        uint256 currentReserve = INITIAL_BALANCE;
        uint256 buyAmount = 2e18;

        // buy and sell stable coins until treasury balance is less than treasury target
        while (treasuryBalance < TREASURY_REVENUE_TARGET) {
            cheats.prank(account1);
            djed.buyStableCoins{value: buyAmount}(
                account1,
                UI_FEE,
                UI_DEVELOPER
            );

            uint256 amountReceived = amountAfterDeductionInSC(
                buyAmount,
                treasuryBalance,
                nSC,
                currentReserve
            );

            (
                uint256 fee,
                uint256 t_fee,
                uint256 ui_fee,
                uint256 totalFees
            ) = calculateFees(buyAmount, treasuryBalance);

            uint256 amountReceivedInBC = buyAmount - totalFees;

            treasuryBalance += t_fee;
            nSC += amountReceived;
            currentReserve += (buyAmount - totalFees + fee);

            // linearly decreasing treasury fee and other tests
            assertEq(TREASURY.balance, treasuryBalance);
            assertEq(djed.stableCoin().balanceOf(account1), amountReceived);
            assertEq(djed.stableCoin().totalSupply(), nSC);
            assertEq(R(djed), currentReserve);

            cheats.prank(account1);
            djed.sellStableCoins(
                amountReceived,
                account1,
                UI_FEE,
                UI_DEVELOPER
            );

            (fee, t_fee, ui_fee, totalFees) = calculateFees(
                amountReceivedInBC,
                treasuryBalance
            );

            treasuryBalance += t_fee;
            nSC -= amountReceived;
            currentReserve -= amountReceivedInBC;
            currentReserve += fee;

            assertEq(TREASURY.balance, treasuryBalance);
            assertEq(djed.stableCoin().balanceOf(account1), 0);
            assertEq(djed.stableCoin().totalSupply(), nSC);
            assertEq(R(djed), currentReserve);
        }

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account1, UI_FEE, UI_DEVELOPER); // 1 ADA

        // treasury fee must be 0
        treasuryBalance += 0;
        assertEq(TREASURY.balance, treasuryBalance);
    }

    function testBuyReserveCoinsBelowThreshold() public {
        uint256 reserve = INITIAL_BALANCE;

        assertTrue(djed.stableCoin().totalSupply() <= THRESHOLD_NUMBER_SC);

        uint256 buyAmount = 1e18; // 1 ADA

        // Buying reserve coin for account (account 3) different than msg.sender (account 1)
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account3, UI_FEE, UI_DEVELOPER); // 1 ADA

        (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        ) = calculateFees(buyAmount, 0);

        // expected reserve coins minted
        uint256 amtReceived = amountAfterDeductionInRC(
            buyAmount,
            0,
            0,
            0,
            reserve
        ); // 1.86 SC

        // expected reserve
        reserve += (buyAmount - totalFees + fee); // 1 + 0.93 ADA

        assertEq(djed.stableCoin().balanceOf(account1), 0);
        assertEq(djed.stableCoin().balanceOf(account3), 0);
        assertEq(djed.reserveCoin().balanceOf(account3), amtReceived);
        assertEq(R(djed), reserve);
        assertEq(UI_DEVELOPER.balance, ui_fee);
        assertEq(TREASURY.balance, t_fee);
        assertEq(djed.stableCoin().totalSupply(), 0);
        assertEq(djed.reserveCoin().totalSupply(), amtReceived);
    }

    function testBuyReserveCoinsAboveThreshold() public {
        uint256 nSC = 0;
        uint256 reserve = INITIAL_BALANCE;
        uint256 treasuryBalance = 0;
        uint256 uiDeveloperBalance = 0;

        uint256 buyAmount = 2e18;

        cheats.prank(account1);
        djed.buyStableCoins{value: buyAmount}(account3, UI_FEE, UI_DEVELOPER); // 1 ADA

        uint256 scReceived = amountAfterDeductionInSC(
            buyAmount,
            treasuryBalance,
            nSC,
            reserve
        );

        (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        ) = calculateFees(buyAmount, 0);

        nSC += scReceived;
        reserve += (buyAmount - totalFees + fee);
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;

        assertEq(djed.stableCoin().balanceOf(account3), scReceived);
        assertTrue(djed.stableCoin().totalSupply() >= THRESHOLD_NUMBER_SC);
        assertTrue(isRatioBelowMax(nSC, reserve));

        buyAmount = 1e16;

        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account3, UI_FEE, UI_DEVELOPER); // 1 ADA

        (fee, t_fee, ui_fee, totalFees) = calculateFees(
            buyAmount,
            treasuryBalance
        );

        // expected reserve coins minted
        uint256 amtReceived = amountAfterDeductionInRC(
            buyAmount,
            treasuryBalance,
            nSC,
            0,
            reserve
        );

        reserve += (buyAmount - totalFees + fee);
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;

        assertEq(djed.stableCoin().balanceOf(account1), 0);
        assertEq(djed.stableCoin().balanceOf(account3), nSC);
        assertEq(djed.reserveCoin().balanceOf(account3), amtReceived);
        assertEq(R(djed), reserve);
        assertEq(UI_DEVELOPER.balance, uiDeveloperBalance);
        assertEq(TREASURY.balance, treasuryBalance);
        assertEq(djed.stableCoin().totalSupply(), nSC);
        assertEq(djed.reserveCoin().totalSupply(), amtReceived);
    }

    function testSellReserveCoins() public {
        uint256 nRC = 0;
        uint256 reserve = INITIAL_BALANCE;
        uint256 treasuryBalance = 0;
        uint256 uiDeveloperBalance = 0;

        assertTrue(djed.stableCoin().totalSupply() <= THRESHOLD_NUMBER_SC);

        uint256 buyAmount = 1e18; // 1 ADA

        // Buying reserve coin for account (account 3) different than msg.sender (account 1)
        cheats.prank(account1);
        djed.buyReserveCoins{value: buyAmount}(account1, UI_FEE, UI_DEVELOPER);

        (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        ) = calculateFees(buyAmount, 0);

        // expected reserve coins minted
        uint256 amtReceived = amountAfterDeductionInRC(
            buyAmount,
            0,
            0,
            0,
            reserve
        );

        // expected reserve
        reserve += (buyAmount - totalFees + fee);
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;
        nRC += amtReceived;

        assertEq(R(djed), reserve);
        assertEq(UI_DEVELOPER.balance, ui_fee);
        assertEq(TREASURY.balance, t_fee);
        assertEq(djed.reserveCoin().balanceOf(account1), amtReceived);

        cheats.prank(account1);
        djed.sellReserveCoins(amtReceived, account3, UI_FEE, UI_DEVELOPER);

        uint256 expectedPreFeeBC = (rcTargetPrice(nRC, 0, reserve) *
            amtReceived) / RC_DECIMAL_SCALING_FACTOR;

        (fee, t_fee, ui_fee, totalFees) = calculateFees(
            expectedPreFeeBC,
            treasuryBalance
        );

        uint256 expectedBC = expectedPreFeeBC - totalFees;

        reserve -= expectedPreFeeBC;
        reserve += fee;
        treasuryBalance += t_fee;
        uiDeveloperBalance += ui_fee;
        nRC -= amtReceived;

        assertEq(account3.balance, expectedBC);
        assertEq(djed.stableCoin().balanceOf(account1), 0);
        assertEq(djed.stableCoin().balanceOf(account3), 0);
        assertEq(djed.reserveCoin().balanceOf(account3), 0);
        assertEq(R(djed), reserve);
        assertEq(UI_DEVELOPER.balance, uiDeveloperBalance);
        assertEq(TREASURY.balance, treasuryBalance);
        assertEq(djed.stableCoin().totalSupply(), 0);
        assertEq(djed.reserveCoin().totalSupply(), 0);
    }
}
