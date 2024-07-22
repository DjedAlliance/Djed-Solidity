// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "@hebeswap/IStdReference.sol";
import "./IOracle.sol";

contract HebeSwapOracle is IOracle {
    IStdReference public immutable ref;
    uint256 public immutable scalingFactor;
    string public immutable baseToken;
    string public immutable quoteToken;

    constructor(IStdReference _ref, uint8 _decimals, uint8 _hebeSwapDecimals, string memory _baseToken, string memory _quoteToken) {
        ref = _ref;
        scalingFactor = 10**(uint256(_decimals - _hebeSwapDecimals) );
        baseToken = _baseToken;
        quoteToken = _quoteToken;
    }

    function acceptTermsOfService() external {}

    function readData() external view returns (uint256) {
        IStdReference.ReferenceData memory data = ref.getReferenceData(baseToken, quoteToken);
        return (uint256(int256(data.rate)) * scalingFactor);
    }
}
