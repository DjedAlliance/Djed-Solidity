// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../Djed.sol";

contract Utilities {
    /// System parameters:

    uint256 constant SCALING_FACTOR = 1e24;
    uint256 constant INITIAL_BALANCE = 1e18; // 1 ADA

    uint256 constant SC_DECIMAL_SCALING_FACTOR = 1e6;
    uint256 constant RC_DECIMAL_SCALING_FACTOR = 1e6;

    uint256 constant RESERVE_RATIO_MIN = (SCALING_FACTOR * 110) / 100;
    uint256 constant RESERVE_RATIO_MAX = (SCALING_FACTOR * 170) / 100;
    uint256 constant FEE = (1 * SCALING_FACTOR) / 100; // 1 %
    uint256 constant RESERVE_COIN_WHOLE_MINIMUM_PRICE = 1e18;
    uint256 constant RESERVE_COIN_WHOLE_INITIAL_PRICE = 1e20;
    uint256 THRESHOLD_NUMBER_SC = 1e6;
    uint256 TX_LIMIT = 200e6; // 200 SC

    uint64 constant ORACLE_EXCHANGE_RATE = 1e18 / 2; // 1 USD = 0.5 ADA (ADA per USD)

    address constant TREASURY = 0x078D888E40faAe0f32594342c85940AF3949E666;
    uint256 INITIAL_TREASURY_FEE = 0; // 0%
    uint256 TREASURY_REVENUE_TARGET = 0; // 0 ADA

    /// Test environment:

    address account1 = 0x766FCe3d50d795Fe6DcB1020AB58bccddd5C5c77;
    address account2 = 0xd109c2fCfc7fE7AE9ccdE37529E50772053Eb7EE;
    address account3 = 0x8B6C3b7e528e0ed125b71ED2059425Abdc477515;

    address UI_DEVELOPER = 0x3EA53fA26b41885cB9149B62f0b7c0BAf76C78D4;
    uint256 UI_FEE = 0; // 0%

    // Utilities

    // fee calculation (in ADA scale)
    function calculateFees(uint256 amount, uint256 currentTreasuryBalance)
        public
        view
        returns (
            uint256 fee,
            uint256 t_fee,
            uint256 ui_fee,
            uint256 totalFees
        )
    {
        fee = (amount * FEE) / SCALING_FACTOR; // 1% of amt asked
        t_fee =
            (amount * calculateTreasuryFee(currentTreasuryBalance)) /
            SCALING_FACTOR; // 5% of amt asked
        ui_fee = (amount * UI_FEE) / SCALING_FACTOR; // 1% of amt asked
        totalFees = t_fee + ui_fee + fee; // sum of above fees (7%)

        return (fee, t_fee, ui_fee, totalFees);
    }

    function R(Djed c) internal view returns (uint256) {
        return address(c).balance;
    }

    function L(Djed c) internal view returns (uint256) {
        uint256 sSC = c.stableCoin().totalSupply();
        return (sSC * scPrice(sSC, R(c))) / SC_DECIMAL_SCALING_FACTOR;
    }

    function E(Djed c) internal view returns (uint256) {
        return R(c) - L(c);
    }

    function ratio(Djed c) internal view returns (uint256) {
        return R(c) / L(c);
    }

    // Liabilities (in weis)
    function L(uint256 nSC, uint256 reserve) public pure returns (uint256) {
        return (nSC * scPrice(nSC, reserve)) / SC_DECIMAL_SCALING_FACTOR;
    }

    // Equity (in weis)
    function E(uint256 nSC, uint256 reserve) public pure returns (uint256) {
        return reserve - L(nSC, reserve);
    }

    function rcTargetPrice(
        uint256 nRC,
        uint256 nSC,
        uint256 reserve
    ) internal pure returns (uint256) {
        require(nRC != 0);

        return (E(nSC, reserve) * RC_DECIMAL_SCALING_FACTOR) / nRC;
    }

    function rcPrice(
        uint256 nRC,
        uint256 nSC,
        uint256 reserve
    ) internal pure returns (uint256) {
        if (nRC == 0) {
            return RESERVE_COIN_WHOLE_MINIMUM_PRICE;
        } else {
            return
                Math.max(
                    rcTargetPrice(nRC, nSC, reserve),
                    RESERVE_COIN_WHOLE_MINIMUM_PRICE
                );
        }
    }

    // Returns ADA per USD exchange rate
    function scPrice(uint256 nSC, uint256 reserve)
        internal
        pure
        returns (uint256)
    {
        if (nSC == 0) {
            return ORACLE_EXCHANGE_RATE;
        } else {
            return
                Math.min(
                    ORACLE_EXCHANGE_RATE,
                    (reserve * SC_DECIMAL_SCALING_FACTOR) / nSC
                );
        }
    }

    // Amount received after deducting total fees (in Stable Coin)
    function amountAfterDeductionInSC(
        uint256 amount,
        uint256 currentTreasuryBalance,
        uint256 nSC,
        uint256 reserve
    ) public view returns (uint256 expectedAmount) {
        (, , , uint256 totalFees) = calculateFees(
            amount,
            currentTreasuryBalance
        );

        expectedAmount =
            (amount - totalFees) /
            (scPrice(nSC, reserve) / SC_DECIMAL_SCALING_FACTOR);
    }

    function amountAfterDeductionInRC(
        uint256 amount,
        uint256 currentTreasuryBalance,
        uint256 nSC,
        uint256 nRC,
        uint256 reserve
    ) public view returns (uint256 expectedAmount) {
        (, , , uint256 totalFees) = calculateFees(
            amount,
            currentTreasuryBalance
        );

        expectedAmount =
            (amount - totalFees) /
            (rcPrice(nRC, nSC, reserve) / RC_DECIMAL_SCALING_FACTOR);
    }

    // Calculate treasury fee
    function calculateTreasuryFee(uint256 currentTreasuryRevenue)
        public
        view
        returns (uint256 t_fee)
    {
        t_fee = (
            currentTreasuryRevenue >= TREASURY_REVENUE_TARGET
                ? 0
                : INITIAL_TREASURY_FEE -
                    (INITIAL_TREASURY_FEE * currentTreasuryRevenue) /
                    TREASURY_REVENUE_TARGET
        );
    }

    function isRatioAboveMin(uint256 nSC, uint256 reserve)
        public
        pure
        returns (bool)
    {
        return
            reserve * SCALING_FACTOR * SC_DECIMAL_SCALING_FACTOR >
            nSC * scPrice(nSC, reserve) * RESERVE_RATIO_MIN;
    }

    function isRatioBelowMax(uint256 nSC, uint256 reserve)
        public
        pure
        returns (bool)
    {
        return
            reserve * SCALING_FACTOR * SC_DECIMAL_SCALING_FACTOR <
            nSC * scPrice(nSC, reserve) * RESERVE_RATIO_MAX;
    }
}
