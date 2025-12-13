// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Coin.sol";
import "./IOracle.sol";

contract Djed is ReentrancyGuard {
    IOracle public oracle;
    Coin public stableCoin;
    Coin public reserveCoin;

    // 🔹 NEW: Token metadata (Issue #18 fix)
    string public stableCoinName;
    string public stableCoinSymbol;
    string public reserveCoinName;
    string public reserveCoinSymbol;
    bool private coinsInitialized;

    // Treasury Parameters:
    address public immutable treasury;
    uint256 public immutable initialTreasuryFee;
    uint256 public immutable treasuryRevenueTarget;
    uint256 public treasuryRevenue = 0;

    // Djed Parameters:
    uint256 public immutable reserveRatioMin;
    uint256 public immutable reserveRatioMax;
    uint256 public immutable fee;
    uint256 public immutable thresholdSupplySC;
    uint256 public immutable rcMinPrice;
    uint256 public immutable rcInitialPrice;
    uint256 public immutable txLimit;

    // Scaling factors:
    uint256 public immutable scalingFactor;
    uint256 public scDecimalScalingFactor;
    uint256 public rcDecimalScalingFactor;

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

        oracle = IOracle(oracleAddress);
        oracle.acceptTermsOfService();
    }

    // 🔹 NEW: One-time initialization function
    function initializeCoins(
        string memory _stableCoinName,
        string memory _stableCoinSymbol,
        string memory _reserveCoinName,
        string memory _reserveCoinSymbol
    ) external {
        require(!coinsInitialized, "Coins already initialized");

        stableCoinName = _stableCoinName;
        stableCoinSymbol = _stableCoinSymbol;
        reserveCoinName = _reserveCoinName;
        reserveCoinSymbol = _reserveCoinSymbol;

        stableCoin = new Coin(_stableCoinName, _stableCoinSymbol);
        reserveCoin = new Coin(_reserveCoinName, _reserveCoinSymbol);

        scDecimalScalingFactor = 10 ** stableCoin.decimals();
        rcDecimalScalingFactor = 10 ** reserveCoin.decimals();

        coinsInitialized = true;
    }

    // 🔒 Optional safety check
    modifier coinsReady() {
        require(coinsInitialized, "Coins not initialized");
        _;
    }

    // (Rest of the contract remains unchanged)
}
