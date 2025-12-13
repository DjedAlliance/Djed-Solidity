// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Coin} from "./Coin.sol";
import {IOracleShu} from "./IOracleShu.sol";

contract DjedTefnut is ReentrancyGuard {
    IOracleShu public oracle;
    Coin public stableCoin;
    Coin public reserveCoin;

    // Treasury Parameters:
    address public immutable TREASURY; // address of the treasury
    uint256 public immutable TREASURY_FEE; // fixed treasury fee (no decay)

    // Djed Parameters:
    uint256 public immutable FEE;
    uint256 public immutable THRESHOLD_SUPPLY_SC;
    uint256 public immutable RC_MIN_PRICE;
    uint256 public immutable RC_INITIAL_PRICE;
    uint256 public immutable TX_LIMIT;

    // Scaling factors:
    uint256 public immutable SCALING_FACTOR; // used to represent a decimal number `d` as the uint number `d * SCALING_FACTOR`
    uint256 public immutable SC_DECIMAL_SCALING_FACTOR;
    uint256 public immutable RC_DECIMAL_SCALING_FACTOR;

    event BoughtStableCoins(address indexed buyer, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event SoldStableCoins(address indexed seller, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event BoughtReserveCoins(address indexed buyer, address indexed receiver, uint256 amountRc, uint256 amountBc);
    event SoldReserveCoins(address indexed seller, address indexed receiver, uint256 amountRc, uint256 amountBc);

    constructor(
        address oracleAddress,
        uint256 scalingFactor,
        address treasury,
        uint256 treasuryFee,
        uint256 fee,
        uint256 thresholdSupplySc,
        uint256 rcMinPrice,
        uint256 rcInitialPrice,
        uint256 txLimit
    ) payable {
        stableCoin = new Coin("StableCoin", "SC");
        reserveCoin = new Coin("ReserveCoin", "RC");
        SC_DECIMAL_SCALING_FACTOR = 10 ** stableCoin.decimals();
        RC_DECIMAL_SCALING_FACTOR = 10 ** reserveCoin.decimals();
        SCALING_FACTOR = scalingFactor;

        TREASURY = treasury;
        TREASURY_FEE = treasuryFee;

        FEE = fee;
        THRESHOLD_SUPPLY_SC = thresholdSupplySc;
        RC_MIN_PRICE = rcMinPrice;
        RC_INITIAL_PRICE = rcInitialPrice;
        TX_LIMIT = txLimit;

        oracle = IOracleShu(oracleAddress);
        oracle.acceptTermsOfService();
    }

    // Reserve, Liabilities, Equity (in weis) and Reserve Ratio
    function R(uint256 currentPaymentAmount) public view returns (uint256) {
        return address(this).balance - currentPaymentAmount;
    }

    function L(uint256 _scPrice) internal view returns (uint256) {
        return (stableCoin.totalSupply() * _scPrice) / SC_DECIMAL_SCALING_FACTOR;
    }

    function L() external view returns (uint256) {
        return L(scMaxPrice(0));
    }

    function E(uint256 _scPrice, uint256 currentPaymentAmount) internal view returns (uint256) {
        return R(currentPaymentAmount) - L(_scPrice);
    }

    function E(uint256 currentPaymentAmount) external view returns (uint256) {
        return E(scMaxPrice(currentPaymentAmount), currentPaymentAmount);
    }

    // Ratio functions kept for informational purposes only (no longer restrict transactions)
    function ratio() external view returns (uint256) {
        uint256 liabilities = L(scMaxPrice(0));
        if (liabilities == 0) return type(uint256).max;
        return SCALING_FACTOR * R(0) / liabilities;
    }

    // # Public Trading Functions:
    // scMaxPrice
    function buyStableCoins(address receiver, uint256 feeUi, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 scP = scMaxPrice(msg.value);
        uint256 amountBc = deductFees(msg.value, feeUi, ui);
        uint256 amountSc = (amountBc * SC_DECIMAL_SCALING_FACTOR) / scP;
        require(amountSc <= TX_LIMIT || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "buySC: tx limit exceeded");
        require(amountSc > 0, "buySC: receiving zero SCs");
        stableCoin.mint(receiver, amountSc);
        // Reserve ratio check removed in Tefnut
        emit BoughtStableCoins(msg.sender, receiver, amountSc, msg.value);
    }

    function sellStableCoins(uint256 amountSc, address receiver, uint256 feeUi, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(stableCoin.balanceOf(msg.sender) >= amountSc, "sellSC: insufficient SC balance");
        require(amountSc <= TX_LIMIT || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "sellSC: tx limit exceeded");
        uint256 scP = scMinPrice(0);
        uint256 value = (amountSc * scP) / SC_DECIMAL_SCALING_FACTOR;
        uint256 amountBc = deductFees(value, feeUi, ui);
        require(amountBc > 0, "sellSC: receiving zero BCs");
        stableCoin.burn(msg.sender, amountSc);
        transferEth(receiver, amountBc);
        emit SoldStableCoins(msg.sender, receiver, amountSc, amountBc);
    }

    function buyReserveCoins(address receiver, uint256 feeUi, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 scP = scMinPrice(msg.value);
        uint256 rcBp = rcBuyingPrice(scP, msg.value);
        uint256 amountBc = deductFees(msg.value, feeUi, ui);
        require(amountBc <= (TX_LIMIT * scP) / SC_DECIMAL_SCALING_FACTOR || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "buyRC: tx limit exceeded");
        uint256 amountRc = (amountBc * RC_DECIMAL_SCALING_FACTOR) / rcBp;
        require(amountRc > 0, "buyRC: receiving zero RCs");
        reserveCoin.mint(receiver, amountRc);
        // Reserve ratio check removed in Tefnut
        emit BoughtReserveCoins(msg.sender, receiver, amountRc, msg.value);
    }

    function sellReserveCoins(uint256 amountRc, address receiver, uint256 feeUi, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(reserveCoin.balanceOf(msg.sender) >= amountRc, "sellRC: insufficient RC balance");
        uint256 scP = scMaxPrice(0);
        uint256 value = (amountRc * rcTargetPrice(scP, 0)) / RC_DECIMAL_SCALING_FACTOR;
        require(value <= (TX_LIMIT * scP) / SC_DECIMAL_SCALING_FACTOR || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "sellRC: tx limit exceeded");
        uint256 amountBc = deductFees(value, feeUi, ui);
        require(amountBc > 0, "sellRC: receiving zero BCs");
        reserveCoin.burn(msg.sender, amountRc);
        transferEth(receiver, amountBc);
        // Reserve ratio check removed in Tefnut
        emit SoldReserveCoins(msg.sender, receiver, amountRc, amountBc);
    }

    // sellBothCoins function removed in Tefnut

    // # Auxiliary Functions

    function deductFees(uint256 value, uint256 feeUi, address ui) internal returns (uint256) {
        uint256 f = (value * FEE) / SCALING_FACTOR;
        uint256 fUi = (value * feeUi) / SCALING_FACTOR;
        uint256 fT = (value * TREASURY_FEE) / SCALING_FACTOR; // Fixed treasury fee (no decay)
        transferEth(TREASURY, fT);
        transferEth(ui, fUi);
        // transferEth(address(this), f); // this happens implicitly, and thus `f` is effectively transferred to the reserve.
        return value - f - fUi - fT; // amountBc
    }

    // isRatioAboveMin and isRatioBelowMax functions removed in Tefnut

    // # Price Functions: return the price in weis for 1 whole coin.

    function scPrice(uint256 currentPaymentAmount, uint256 scTargetPrice) private view returns (uint256) {
        uint256 supplySc = stableCoin.totalSupply();
        return supplySc == 0
            ? scTargetPrice
            : Math.min(scTargetPrice, (R(currentPaymentAmount) * SC_DECIMAL_SCALING_FACTOR) / supplySc);
    }

    function scMaxPrice(uint256 currentPaymentAmount) public view returns (uint256) {
        (uint256 scTargetPrice,) = oracle.readMaxPrice();
        return scPrice(currentPaymentAmount, scTargetPrice);
    }

    function scMinPrice(uint256 currentPaymentAmount) public view returns (uint256) {
        (uint256 scTargetPrice,) = oracle.readMinPrice();
        return scPrice(currentPaymentAmount, scTargetPrice);
    }

    function rcTargetPrice(uint256 currentPaymentAmount) external view returns (uint256) {
        return rcTargetPrice(scMaxPrice(currentPaymentAmount), currentPaymentAmount);
    }

    function rcTargetPrice(uint256 _scPrice, uint256 currentPaymentAmount) internal view returns (uint256) {
        uint256 supplyRc = reserveCoin.totalSupply();
        require(supplyRc != 0, "RC supply is zero");
        return (E(_scPrice, currentPaymentAmount) * RC_DECIMAL_SCALING_FACTOR) / supplyRc;
    }

    function rcBuyingPrice(uint256 currentPaymentAmount) external view returns (uint256) {
        return rcBuyingPrice(scMaxPrice(currentPaymentAmount), currentPaymentAmount);
    }

    function rcBuyingPrice(uint256 _scPrice, uint256 currentPaymentAmount) internal view returns (uint256) {
        return reserveCoin.totalSupply() == 0
            ? RC_INITIAL_PRICE
            : Math.max(rcTargetPrice(_scPrice, currentPaymentAmount), RC_MIN_PRICE);
    }

    function transferEth(address receiver, uint256 amount) internal {
        (bool success,) = payable(receiver).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}
