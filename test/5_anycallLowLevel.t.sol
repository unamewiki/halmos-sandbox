// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

// import Halmos cheatcodes
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

contract MockERC20 {

    mapping(address => uint) public balanceOf;
    mapping(address => mapping (address => uint)) public allowance;

    constructor() {
        balanceOf[msg.sender] = 1e27;
    }

    function transfer(address to, uint amount) public {
        _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public {
        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        _transfer(from, to, amount);
    }

    // oops, accidentally public
    function _transfer(address from, address to, uint amount) public {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function approve(address spender, uint amount) public {
        allowance[msg.sender][spender] = amount;
    }
}

contract Test5 is Test, SymTest {
    address owner = address(0xc0ffee);
    address badguy = address(0xdeadbeef);

    MockERC20 token;

    function setUp() public {
        vm.prank(owner);
        token = new MockERC20();
    }

    /// does not find the bug
    function test_anycallLowLevel(bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(owner);

        vm.prank(badguy);
        (bool succ, bytes memory result) = address(token).call(data);

        uint256 balanceAfter = token.balanceOf(owner);
        assertEq(balanceBefore, balanceAfter);
    }

    function test_anycallLowLevelExplicit() external {
        bytes memory data = svm.createBytes(100, 'data');
        uint256 balanceBefore = token.balanceOf(owner);

        vm.prank(badguy);
        (bool succ, bytes memory result) = address(token).call(data);

        uint256 balanceAfter = token.balanceOf(owner);
        assertEq(balanceBefore, balanceAfter);
    }
}
