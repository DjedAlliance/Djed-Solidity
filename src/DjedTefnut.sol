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
    uint256 public immutable TREASURY_FEE; // fixed fee to fund the treasury

    // Djed Parameters:
    uint256 public immutable FEE;
    uint256 public immutable THRESHOLD_SUPPLY_SC;
    uint256 public immutable RC_MIN_PRICE;
    uint256 public immutable RC_INITIAL_PRICE;
    uint256 public immutable TX_LIMIT;

    // Scaling factors:
    uint256 public immutable SCALING_FACTOR; // used to represent a decimal number `d` as the uint number `d * scalingFactor`
    uint256 public immutable SC_DECIMAL_SCALING_FACTOR;
    uint256 public immutable RC_DECIMAL_SCALING_FACTOR;

    event BoughtStableCoins(address indexed buyer, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event SoldStableCoins(address indexed seller, address indexed receiver, uint256 amountSc, uint256 amountBc);
    event BoughtReserveCoins(address indexed buyer, address indexed receiver, uint256 amountRc, uint256 amountBc);
    event SoldReserveCoins(address indexed seller, address indexed receiver, uint256 amountRc, uint256 amountBc);

    constructor(
        address oracleAddress, uint256 _scalingFactor,
        address _treasury, uint256 _treasuryFee,
        uint256 _fee, uint256 _thresholdSupplySc, uint256 _rcMinPrice, uint256 _rcInitialPrice, uint256 _txLimit
    ) payable {
        stableCoin = new Coin("StableCoin", "SC");
        reserveCoin = new Coin("ReserveCoin", "RC");
        SC_DECIMAL_SCALING_FACTOR = 10**stableCoin.decimals();
        RC_DECIMAL_SCALING_FACTOR = 10**reserveCoin.decimals();
        SCALING_FACTOR = _scalingFactor;

        TREASURY = _treasury;
        TREASURY_FEE = _treasuryFee;

        FEE = _fee;
        THRESHOLD_SUPPLY_SC = _thresholdSupplySc;
        RC_MIN_PRICE = _rcMinPrice;
        RC_INITIAL_PRICE = _rcInitialPrice;
        TX_LIMIT = _txLimit;

        oracle = IOracleShu(oracleAddress);
        oracle.acceptTermsOfService();
    }

    // Reserve, Liabilities, Equity (in weis)
    function R(uint256 _currentPaymentAmount) public view returns (uint256) {
        return address(this).balance - _currentPaymentAmount;
    }

    function L(uint256 _scPrice) internal view returns (uint256) {
        return (stableCoin.totalSupply() * _scPrice) / SC_DECIMAL_SCALING_FACTOR;
    }

    function L() external view returns (uint256) {
        return L(scMaxPrice(0));
    }

    function E(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return R(_currentPaymentAmount) - L(_scPrice);
    }

    function E(uint256 _currentPaymentAmount) external view returns (uint256) {
        return E(scMaxPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    // # Public Trading Functions:
    function buyStableCoins(address receiver, uint256 feeUi, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 amountBc = deductFees(msg.value, feeUi, ui);
        uint256 amountSc = (amountBc * SC_DECIMAL_SCALING_FACTOR) / scMaxPrice(msg.value);
        require(amountSc <= TX_LIMIT || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "buySC: tx limit exceeded");
        require(amountSc > 0, "buySC: receiving zero SCs");
        stableCoin.mint(receiver, amountSc);
        emit BoughtStableCoins(msg.sender, receiver, amountSc, msg.value);
    }

    function sellStableCoins(uint256 amountSc, address receiver, uint256 feeUi, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(stableCoin.balanceOf(msg.sender) >= amountSc, "sellSC: insufficient SC balance");
        require(amountSc <= TX_LIMIT || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "sellSC: tx limit exceeded");
        stableCoin.burn(msg.sender, amountSc);
        uint256 amountBc = deductFees((amountSc * scMinPrice(0)) / SC_DECIMAL_SCALING_FACTOR, feeUi, ui);
        require(amountBc > 0, "sellSC: receiving zero BCs");
        transfer(receiver, amountBc);
        emit SoldStableCoins(msg.sender, receiver, amountSc, amountBc);
    }

    function buyReserveCoins(address receiver, uint256 feeUi, address ui) external payable nonReentrant {
        oracle.updateOracleValues();
        uint256 amountBc = deductFees(msg.value, feeUi, ui);
        uint256 minPrice = scMinPrice(msg.value);
        require(amountBc <= (TX_LIMIT * minPrice) / SC_DECIMAL_SCALING_FACTOR || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "buyRC: tx limit exceeded");
        uint256 amountRc = (amountBc * RC_DECIMAL_SCALING_FACTOR) / rcBuyingPrice(minPrice, msg.value);
        require(amountRc > 0, "buyRC: receiving zero RCs");
        reserveCoin.mint(receiver, amountRc);
        emit BoughtReserveCoins(msg.sender, receiver, amountRc, msg.value);
    }

    function sellReserveCoins(uint256 amountRc, address receiver, uint256 feeUi, address ui) external nonReentrant {
        oracle.updateOracleValues();
        require(reserveCoin.balanceOf(msg.sender) >= amountRc, "sellRC: insufficient RC balance");
        uint256 maxPrice = scMaxPrice(0);
        require((amountRc * rcTargetPrice(maxPrice, 0)) / RC_DECIMAL_SCALING_FACTOR <= (TX_LIMIT * maxPrice) / SC_DECIMAL_SCALING_FACTOR || stableCoin.totalSupply() < THRESHOLD_SUPPLY_SC, "sellRC: tx limit exceeded");
        reserveCoin.burn(msg.sender, amountRc);
        uint256 amountBc = deductFees((amountRc * rcTargetPrice(maxPrice, 0)) / RC_DECIMAL_SCALING_FACTOR, feeUi, ui);
        require(amountBc > 0, "sellRC: receiving zero BCs");
        transfer(receiver, amountBc);
        emit SoldReserveCoins(msg.sender, receiver, amountRc, amountBc);
    }

    // # Auxiliary Functions

    function deductFees(uint256 value, uint256 feeUi, address ui) internal returns (uint256) {
        uint256 totalFees = ((value * FEE) + (value * feeUi) + (value * TREASURY_FEE)) / SCALING_FACTOR;
        transfer(TREASURY, (value * TREASURY_FEE) / SCALING_FACTOR);
        transfer(ui, (value * feeUi) / SCALING_FACTOR);
        return value - totalFees;
    }

    // # Price Functions: return the price in weis for 1 whole coin.

    function scPrice(uint256 _currentPaymentAmount, uint256 scTargetPrice) private view returns (uint256) {
        return stableCoin.totalSupply() == 0
                ? scTargetPrice
                : Math.min(scTargetPrice, (R(_currentPaymentAmount) * SC_DECIMAL_SCALING_FACTOR) / stableCoin.totalSupply());
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
    }

    function rcTargetPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256)
    {
        require(reserveCoin.totalSupply() != 0, "RC supply is zero");
        return (E(_scPrice, _currentPaymentAmount) * RC_DECIMAL_SCALING_FACTOR) / reserveCoin.totalSupply();
    }

    function rcBuyingPrice(uint256 _currentPaymentAmount) external view returns (uint256) {
        return rcBuyingPrice(scMaxPrice(_currentPaymentAmount), _currentPaymentAmount);
    }

    function rcBuyingPrice(uint256 _scPrice, uint256 _currentPaymentAmount) internal view returns (uint256) {
        return reserveCoin.totalSupply() == 0
                ? RC_INITIAL_PRICE
                : Math.max(rcTargetPrice(_scPrice, _currentPaymentAmount), RC_MIN_PRICE);
    }

    function transfer(address receiver, uint256 amount) internal {
        (bool success, ) = payable(receiver).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}
