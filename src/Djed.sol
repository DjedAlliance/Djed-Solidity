// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Coin.sol";
import "./IOracle.sol";

contract Djed {
    IOracle public oracle;
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
        uint256 _fee, uint256 _thresholdSupplySC, uint256 _rcMinPrice, uint256 _txLimit
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
        txLimit = _txLimit;

        oracle = IOracle(oracleAddress);
        oracle.acceptTermsOfService();
    }

    // Reserve, Liabilities, Equity (in weis) and Reserve Ratio
    function R(uint256 _currentPaymentAmount) public view returns (uint256) {
        return address(this).balance - _currentPaymentAmount;
    }

    function L(uint256 _scPrice) internal view returns (uint256) {
        return (stableCoin.totalSupply() * _scPrice) / scDecimalScalingFactor;
    }

    function L() external view returns (uint256) {
        return L(scPrice(0));
    }

    function E(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return R(_currentPaymentAmount) - L(_scPrice);
    }

    function E(uint256 _currentPaymentAmount) external view returns (uint256) {
        return E(scPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function ratio() external view returns (uint256) {
        return scalingFactor * R(0) / L(scPrice(0));
    }

    // # Public Trading Functions:

    function buyStableCoins(address receiver, uint256 feeUI, address ui) external payable {
        uint256 scP = scPrice(msg.value);
        uint256 amountBC = deductFees(msg.value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        uint256 amountSC = (amountBC * scDecimalScalingFactor) / scP;
        require(amountSC <= txLimit || stableCoin.totalSupply() <= thresholdSupplySC, "buySC: tx limit exceeded");
        require(amountSC > 0, "buySC: receiving zero SCs");
        stableCoin.mint(receiver, amountSC);
        require(isRatioAboveMin(scP), "buySC: ratio below min");
        emit BoughtStableCoins(msg.sender, receiver, amountSC, msg.value);
    }

    function sellStableCoins(uint256 amountSC, address receiver, uint256 feeUI, address ui) external {
        require(stableCoin.balanceOf(msg.sender) >= amountSC, "sellSC: insufficient SC balance");
        require(amountSC <= txLimit || stableCoin.totalSupply() <= thresholdSupplySC, "sellSC: tx limit exceeded");
        uint256 scP = scPrice(0);
        uint256 value = (amountSC * scP) / scDecimalScalingFactor;
        uint256 amountBC = deductFees(value, feeUI, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellSC: receiving zero BCs");
        stableCoin.burn(msg.sender, amountSC);
        payable(receiver).transfer(amountBC);
        emit SoldStableCoins(msg.sender, receiver, amountSC, amountBC);
    }

    function buyReserveCoins(address receiver, uint256 fee_ui, address ui) external payable {
        uint256 scP = scPrice(msg.value);
        uint256 rcBP = rcBuyingPrice(scP, msg.value);
        require(msg.value <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() <= thresholdSupplySC,
            "buyRC: tx limit exceeded"
        );
        uint256 amountBC = deductFees(msg.value, fee_ui, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        uint256 amountRC = (amountBC * rcDecimalScalingFactor) / rcBP;
        require(amountRC > 0, "buyRC: receiving zero RCs");
        reserveCoin.mint(receiver, amountRC);
        require(isRatioBelowMax(scP) || stableCoin.totalSupply() <= thresholdSupplySC, "buyRC: ratio above max");
        emit BoughtReserveCoins(msg.sender, receiver, amountRC, msg.value);
    }

    function sellReserveCoins(uint256 amountRC, address receiver, uint256 fee_ui, address ui) external {
        require(reserveCoin.balanceOf(msg.sender) >= amountRC, "sellRC: insufficient RC balance");
        uint256 scP = scPrice(0);
        uint256 value = (amountRC * rcTargetPrice(scP, 0)) / rcDecimalScalingFactor;
        require(value <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() <= thresholdSupplySC,
            "sellRC: tx limit exceeded"
        );
        uint256 amountBC = deductFees(value, fee_ui, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellRC: receiving zero BCs");
        reserveCoin.burn(msg.sender, amountRC);
        payable(receiver).transfer(amountBC);
        require(isRatioAboveMin(scP), "sellRC: ratio below min");
        emit SoldReserveCoins(msg.sender, receiver, amountRC, amountBC);
    }

    function sellBothCoins(uint256 amountSC, uint256 amountRC, address receiver, uint256 fee_ui, address ui) external {
        require(stableCoin.balanceOf(msg.sender) >= amountSC, "sellBoth: insufficient SC balance");
        require(reserveCoin.balanceOf(msg.sender) >= amountRC, "sellBoth: insufficient RC balance");
        uint256 scP = scPrice(0);
        uint256 preR = R(0);
        uint256 preL = L(scP);
        uint256 value = (amountSC * scP) / scDecimalScalingFactor + (amountRC * rcTargetPrice(scP, 0)) / rcDecimalScalingFactor;
        require(value <= (txLimit * scP) / scDecimalScalingFactor || stableCoin.totalSupply() <= thresholdSupplySC,
            "sellBoth: tx limit exceeded"
        );
        stableCoin.burn(msg.sender, amountSC);
        reserveCoin.burn(msg.sender, amountRC);
        uint256 amountBC = deductFees(value, fee_ui, ui); // side-effect: increases `treasuryRevenue` and pays UI and treasury
        require(amountBC > 0, "sellBoth: receiving zero BCs");
        payable(receiver).transfer(amountBC);
        require(R(0) * preL >= preR * L(scP), "sellBoth: reserve ratio decreased"); // R(0)/L(scP) >= preR/preL, avoiding division by zero
        emit SoldBothCoins(msg.sender, receiver, amountSC, amountRC, amountBC);
    }

    // # Auxiliary Functions

    function deductFees(uint256 value, uint256 fee_ui, address ui) internal returns (uint256) {
        uint256 f = (value * fee) / scalingFactor;
        uint256 f_ui = (value * fee_ui) / scalingFactor;
        uint256 f_t = (value * treasuryFee()) / scalingFactor;
        treasuryRevenue += f_t;
        payable(treasury).transfer(f_t);
        payable(ui).transfer(f_ui);
        // payable(address(this)).transfer(f); // this happens implicitly, and thus `f` is effectively transfered to the reserve.
        return value - f - f_ui - f_t; // amountBC
    }

    function isRatioAboveMin(uint256 _scPrice) internal view returns (bool) {
        return R(0) * scalingFactor * scDecimalScalingFactor > stableCoin.totalSupply() * _scPrice * reserveRatioMin;
    }

    function isRatioBelowMax(uint256 _scPrice) internal view returns (bool) {
        return R(0) * scalingFactor * scDecimalScalingFactor < stableCoin.totalSupply() * _scPrice * reserveRatioMax;
    }

    // Treasury Fee: starts as `initialTreasuryFee` and decreases linearly to 0 as the `treasuryRevenue` approaches the `treasuryRevenueTarget`
    function treasuryFee() public view returns (uint256) {
        return (treasuryRevenue >= treasuryRevenueTarget)
                ? 0
                : initialTreasuryFee - ((initialTreasuryFee * treasuryRevenue) / treasuryRevenueTarget);
    }

    // # Price Functions: return the price in weis for 1 whole coin.

    function scPrice(uint256 _currentPaymentAmount) public view returns (uint256) {
        uint256 scTargetPrice = oracle.readData();
        uint256 sSC = stableCoin.totalSupply();
        return sSC == 0
                ? scTargetPrice
                : Math.min(scTargetPrice, (R(_currentPaymentAmount) * scDecimalScalingFactor) / sSC);
    }

    function rcTargetPrice(uint256 _currentPaymentAmount) external view returns (uint256) {
        return rcTargetPrice(scPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function rcTargetPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256)
    {
        uint256 sRC = reserveCoin.totalSupply();
        require(sRC != 0, "RC supply is zero");
        return (E(_scPrice, _currentPaymentAmount) * rcDecimalScalingFactor) / sRC;
    }

    function rcBuyingPrice(uint256 _currentPaymentAmount) external view returns (uint256) {
        return rcBuyingPrice(scPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function rcBuyingPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return reserveCoin.totalSupply() == 0
                ? rcMinPrice
                : Math.max(rcTargetPrice(_scPrice, _currentPaymentAmount), rcMinPrice);
    }
}
