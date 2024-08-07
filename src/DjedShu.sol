// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Coin.sol";
import "./IOracleShu.sol";

contract Djed is ReentrancyGuard {
    IOracleShu public oracle;
    Coin public stableCoin;
    Coin public reserveCoin;

    // Treasury Parameters:
    address public immutable treasury; // address of the treasury
    uint256 public immutable initialTreasuryFee; // initial fee to fund the treasury
    uint256 public immutable treasuryRevenueTarget; // target revenue above which the treasury fee is set to 0
    uint256 public treasuryRevenue = 0; // holds how much has already been paid to the treasury // Mutable state variable

    // Djed Parameters:
    uint256 public immutable reserveRatioMin;
    uint256 public immutable reserveRatioMax;
    uint256 public immutable fee;
    uint256 public immutable thresholdSupplySC;
    uint256 public immutable rcMinPrice;
    uint256 public immutable rcInitialPrice;
    uint256 public immutable txLimit;

    // Scaling factors:
    uint256 public immutable scalingFactor; // used to represent a decimal number `d` as the uint number `d * scalingFactor`
    uint256 public immutable scDecimalScalingFactor;
    uint256 public immutable rcDecimalScalingFactor;

    event BoughtStableCoins(address indexed buyer, address indexed receiver, uint256 amountSC, uint256 amountBC);
    event SoldStableCoins(address indexed seller, address indexed receiver, uint256 amountSC, uint256 amountBC);
    event BoughtReserveCoins(address indexed buyer, address indexed receiver, uint256 amountRC, uint256 amountBC);
    event SoldReserveCoins(address indexed seller, address indexed receiver, uint256 amountRC, uint256 amountBC);
    event SoldBothCoins(address indexed seller, address indexed receiver, uint256 amountSC, uint256 amountRC, uint256 amountBC);

    constructor(
        address oracleAddress, uint256 _scalingFactor,
        address _treasury, uint256 _initialTreasuryFee, uint256 _treasuryRevenueTarget,
        uint256 _reserveRatioMin, uint256 _reserveRatioMax,
        uint256 _fee, uint256 _thresholdSupplySC, uint256 _rcMinPrice, uint256 _rcInitialPrice, uint256 _txLimit
    ) payable {
        stableCoin = new Coin("StableCoin", "SC");
        reserveCoin = new Coin("ReserveCoin", "RC");
        scDecimalScalingFactor = 10**stableCoin.decimals();
        rcDecimalScalingFactor = 10**reserveCoin.decimals();
        scalingFactor = _scalingFactor;

        treasury = _treasury;
        initialTreasuryFee = _initialTreasuryFee;
        treasuryRevenueTarget = _treasuryRevenueTarget;

        reserveRatioMin = _reserveRatioMin;
        reserveRatioMax = _reserveRatioMax;
        fee = _fee;
        thresholdSupplySC = _thresholdSupplySC;
        rcMinPrice = _rcMinPrice;
        rcInitialPrice = _rcInitialPrice;
        txLimit = _txLimit;

        oracle = IOracleShu(oracleAddress);
        oracle.acceptTermsOfService();
    }

    // Reserve, Liabilities, Equity (in weis) and Reserve Ratio
    function R(uint256 _currentPaymentAmount) public view returns (uint256) {
        return address(this).balance - _currentPaymentAmount;
    }

    function L(uint256 _scPrice) internal view returns (uint256) {
        return (stableCoin.totalSupply() * _scPrice) / scDecimalScalingFactor;
    } // sell both coin -> min price

    function L() external view returns (uint256) {
        return L(scMaxPrice(0));
    }

    function E(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return R(_currentPaymentAmount) - L(_scPrice);
    } // rcTargetPrice -> sell RC -> min price

    function E(uint256 _currentPaymentAmount) external view returns (uint256) {
        return E(scMaxPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function ratioMax() external view returns (uint256) {
        return scalingFactor * R(0) / L(scMaxPrice(0));
    }

    function ratioMin() external view returns (uint256) {
        return scalingFactor * R(0) / L(scMinPrice(0));
    }

    // # Public Trading Functions:
    // scMaxPrice
    function buyStableCoins(address receiver, uint256 feeUI, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 scP = scMaxPrice(msg.value);
        uint256 amountBC = deductFees(msg.value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        uint256 amountSC = (amountBC * scDecimalScalingFactor) / scP;
        require(amountSC <= txLimit || stableCoin.totalSupply() < thresholdSupplySC, "buySC: tx limit exceeded");
        require(amountSC > 0, "buySC: receiving zero SCs");
        stableCoin.mint(receiver, amountSC);
        require(isRatioAboveMin(scMaxPrice(0)), "buySC: ratio below min");
        emit BoughtStableCoins(msg.sender, receiver, amountSC, msg.value);
    }

    function sellStableCoins(uint256 amountSC, address receiver, uint256 feeUI, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(stableCoin.balanceOf(msg.sender) >= amountSC, "sellSC: insufficient SC balance");
        require(amountSC <= txLimit || stableCoin.totalSupply() < thresholdSupplySC, "sellSC: tx limit exceeded");
        uint256 scP = scMinPrice(0);
        uint256 value = (amountSC * scP) / scDecimalScalingFactor;
        uint256 amountBC = deductFees(value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellSC: receiving zero BCs");
        stableCoin.burn(msg.sender, amountSC);
        transfer(receiver, amountBC);
        emit SoldStableCoins(msg.sender, receiver, amountSC, amountBC);
    }

    function buyReserveCoins(address receiver, uint256 feeUI, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 scP = scMinPrice(msg.value);
        uint256 rcBP = rcBuyingPrice(scP, msg.value);
        uint256 amountBC = deductFees(msg.value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() < thresholdSupplySC, "buyRC: tx limit exceeded");
        uint256 amountRC = (amountBC * rcDecimalScalingFactor) / rcBP;
        require(amountRC > 0, "buyRC: receiving zero RCs");
        reserveCoin.mint(receiver, amountRC);
        require(isRatioBelowMax(scMaxPrice(0)) || stableCoin.totalSupply() < thresholdSupplySC, "buyRC: ratio above max");
        emit BoughtReserveCoins(msg.sender, receiver, amountRC, msg.value);
    }

    function sellReserveCoins(uint256 amountRC, address receiver, uint256 feeUI, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(reserveCoin.balanceOf(msg.sender) >= amountRC, "sellRC: insufficient RC balance");
        uint256 scP = scMaxPrice(0);
        uint256 value = (amountRC * rcTargetPrice(scP, 0)) / rcDecimalScalingFactor;
        require(value <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() < thresholdSupplySC, "sellRC: tx limit exceeded");
        uint256 amountBC = deductFees(value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellRC: receiving zero BCs");
        reserveCoin.burn(msg.sender, amountRC);
        transfer(receiver, amountBC);
        require(isRatioAboveMin(scMinPrice(0)), "sellRC: ratio below min");
        emit SoldReserveCoins(msg.sender, receiver, amountRC, amountBC);
    }

    function sellBothCoins(uint256 amountSC, uint256 amountRC, address receiver, uint256 feeUI, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(stableCoin.balanceOf(msg.sender) >= amountSC, "sellBoth: insufficient SCs");
        require(reserveCoin.balanceOf(msg.sender) >= amountRC, "sellBoth: insufficient RCs");
        uint256 scP = scMaxPrice(0);
        uint256 preR = R(0);
        uint256 preL = L(scP);
        uint256 value = (amountSC * scP) / scDecimalScalingFactor + (amountRC * rcTargetPrice(scP, 0)) / rcDecimalScalingFactor;
        require(value <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() < thresholdSupplySC, "sellBoth: tx limit exceeded");
        stableCoin.burn(msg.sender, amountSC);
        reserveCoin.burn(msg.sender, amountRC);
        uint256 amountBC = deductFees(value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellBoth: receiving zero BCs");
        transfer(receiver, amountBC);
        require(R(0) * preL >= preR * L(scMinPrice(0)), "sellBoth: ratio decreased"); // R(0)/L(scP) >= preR/preL, avoiding division by zero
        emit SoldBothCoins(msg.sender, receiver, amountSC, amountRC, amountBC);
    }

    // # Auxiliary Functions

    function deductFees(uint256 value, uint256 feeUI, address ui) internal returns (uint256) {
        uint256 f = (value * fee) / scalingFactor;
        uint256 fUI = (value * feeUI) / scalingFactor;
        uint256 fT = (value * treasuryFee()) / scalingFactor;
        treasuryRevenue += fT;
        transfer(treasury, fT);
        transfer(ui, fUI);
        // transfer(address(this), f); // this happens implicitly, and thus `f` is effectively transfered to the reserve.
        return value - f - fUI - fT; // amountBC
    }

    function isRatioAboveMin(uint256 _scPrice) internal view returns (bool) {
        return R(0) * scalingFactor * scDecimalScalingFactor >= stableCoin.totalSupply() * _scPrice * reserveRatioMin;
    }

    function isRatioBelowMax(uint256 _scPrice) internal view returns (bool) {
        return R(0) * scalingFactor * scDecimalScalingFactor <= stableCoin.totalSupply() * _scPrice * reserveRatioMax;
    }

    // Treasury Fee: starts as `initialTreasuryFee` and decreases linearly to 0 as the `treasuryRevenue` approaches the `treasuryRevenueTarget`
    function treasuryFee() public view returns (uint256) {
        return (treasuryRevenue >= treasuryRevenueTarget)
                ? 0
                : initialTreasuryFee - ((initialTreasuryFee * treasuryRevenue) / treasuryRevenueTarget);
    }

    // # Price Functions: return the price in weis for 1 whole coin.

    function scPrice(uint256 _currentPaymentAmount, uint256 scTargetPrice) private view returns (uint256) {
        uint256 sSC = stableCoin.totalSupply();
        return sSC == 0
                ? scTargetPrice
                : Math.min(scTargetPrice, (R(_currentPaymentAmount) * scDecimalScalingFactor) / sSC);
    }

    function scMaxPrice(uint256 _currentPaymentAmount) public view returns (uint256) {
        (uint256 scTargetPrice, ) = oracle.readMaxPrice();
        return scPrice(_currentPaymentAmount, scTargetPrice);
    }

    function scMinPrice(uint256 _currentPaymentAmount) public view returns (uint256) {
        (uint256 scTargetPrice, ) = oracle.readMinPrice();
        return scPrice(_currentPaymentAmount, scTargetPrice);
    }

    function rcTargetPrice(uint256 _currentPaymentAmount) external view returns (uint256) {
        return rcTargetPrice(scMaxPrice(_currentPaymentAmount), _currentPaymentAmount);
    } // for sell rc -> we should use min price

    function rcTargetPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256)
    {
        uint256 sRC = reserveCoin.totalSupply();
        require(sRC != 0, "RC supply is zero");
        return (E(_scPrice, _currentPaymentAmount) * rcDecimalScalingFactor) / sRC;
    }

    function rcBuyingPrice(uint256 _currentPaymentAmount) external view returns (uint256) {
        return rcBuyingPrice(scMaxPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function rcBuyingPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return reserveCoin.totalSupply() == 0
                ? rcInitialPrice
                : Math.max(rcTargetPrice(_scPrice, _currentPaymentAmount), rcMinPrice);
    }

    function transfer(address receiver, uint256 amount) internal {
        (bool success, ) = payable(receiver).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}

// The worst price depends on the operation. For example, for "Buy stablecoin", the worst price is the max price. But, for "sell stablecoin", the worst price is the min price.