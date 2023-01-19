// SPDX-License-Identifier: AEL
pragma solidity ^0.8.0;

import "./utils/Cheatcodes.sol";
import "./utils/Console.sol";
import "./utils/Ctest.sol";

import "../Coin.sol";

contract CoinTest is CTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Coin stableCoin;
    Coin reserveCoin;

    address account1 = 0x766FCe3d50d795Fe6DcB1020AB58bccddd5C5c77;
    address account2 = 0x078D888E40faAe0f32594342c85940AF3949E666;

    uint256 constant MAX_INT = 2**256 - 1;

    function setUp() public {
        stableCoin = new Coin("Stablecoin", "SC");
        reserveCoin = new Coin("ReserveCoin", "RC");
    }

    function testMint(uint256 amount) public {
        stableCoin.mint(account1, amount);
        reserveCoin.mint(account1, amount);
        assertEq(stableCoin.balanceOf(account1), amount);
        assertEq(reserveCoin.balanceOf(account1), amount);
    }

    function testBurn(uint256 amount) public {
        stableCoin.mint(account1, amount);
        stableCoin.burn(account1, amount);
        reserveCoin.mint(account1, amount);
        reserveCoin.burn(account1, amount);
        assertEq(stableCoin.balanceOf(account1), 0);
        assertEq(reserveCoin.balanceOf(account1), 0);
    }

    function testCannotBurnNone(uint256 amount) public {
        if (amount == 0) {
            amount += 1;
        }
        cheats.expectRevert("ERC20: burn amount exceeds balance");
        stableCoin.burn(account1, amount);
        cheats.expectRevert("ERC20: burn amount exceeds balance");
        reserveCoin.burn(account1, amount);
    }

    function testNonOwnerCannotMint(address sender, uint256 amount) public {
        if (sender == address(this)) {
            return;
        }
        cheats.startPrank(sender);
        cheats.expectRevert("Unauthorized");
        stableCoin.mint(sender, amount);
        cheats.expectRevert("Unauthorized");
        reserveCoin.mint(sender, amount);
        cheats.stopPrank();
    }

    function testTrade(uint256 amount) public {
        stableCoin.mint(account1, amount);
        reserveCoin.mint(account1, amount);

        cheats.startPrank(account1);
        stableCoin.transfer(account2, amount);
        reserveCoin.transfer(account2, amount);
        cheats.stopPrank();

        assertEq(stableCoin.balanceOf(account1), 0);
        assertEq(stableCoin.balanceOf(account2), amount);
        assertEq(reserveCoin.balanceOf(account1), 0);
        assertEq(reserveCoin.balanceOf(account2), amount);
    }

    function testCannotTradeNone(uint256 amount) public {
        if (amount == MAX_INT) {
            amount -= 1;
        }
        stableCoin.mint(account1, amount);
        reserveCoin.mint(account1, amount);

        cheats.startPrank(account1);
        cheats.expectRevert("ERC20: transfer amount exceeds balance");
        stableCoin.transfer(account2, amount + 1);
        cheats.expectRevert("ERC20: transfer amount exceeds balance");
        reserveCoin.transfer(account2, amount + 1);
        cheats.stopPrank();
    }

    function testWithdrawTrade(uint256 amount) public {
        stableCoin.mint(account1, amount);
        reserveCoin.mint(account1, amount);

        cheats.startPrank(account1);
        stableCoin.approve(account2, amount);
        reserveCoin.approve(account2, amount);
        cheats.stopPrank();

        cheats.startPrank(account2);
        stableCoin.transferFrom(account1, account2, amount);
        reserveCoin.transferFrom(account1, account2, amount);
        cheats.stopPrank();

        assertEq(stableCoin.balanceOf(account1), 0);
        assertEq(stableCoin.balanceOf(account2), amount);
        assertEq(reserveCoin.balanceOf(account1), 0);
        assertEq(reserveCoin.balanceOf(account2), amount);
    }

    function testCannotWithdrawTooMuch(uint256 amount) public {
        if (amount == MAX_INT) {
            amount -= 1;
        }
        stableCoin.mint(account1, amount);
        reserveCoin.mint(account1, amount);

        cheats.startPrank(account1);
        stableCoin.approve(account2, amount);
        reserveCoin.approve(account2, amount);
        cheats.stopPrank();

        cheats.startPrank(account2);
        cheats.expectRevert("ERC20: insufficient allowance");
        stableCoin.transferFrom(account1, account2, amount + 1);
        cheats.expectRevert("ERC20: insufficient allowance");
        reserveCoin.transferFrom(account1, account2, amount + 1);
        cheats.stopPrank();
    }
}
