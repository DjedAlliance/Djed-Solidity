// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@hebeswap/IStdReference.sol";
import "./IOracle.sol";

contract HebeSwapOracle is IOracle {
    IStdReference public immutable ref;
    uint256 public immutable scalingFactor;

    constructor(IStdReference _ref, uint8 _decimals, uint8 _hebeSwapDecimals) {
        ref = _ref;
        scalingFactor = 10**(uint256(_decimals - _hebeSwapDecimals) );
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        IStdReference.ReferenceData memory data = ref.getReferenceData("ETC", "USDT");
        return (uint256(int256(data.rate)) * scalingFactor);
    }
}
