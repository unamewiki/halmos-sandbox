// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

contract Test13 is Test {
    function test_callToSymbolicAddress(address recipient) external {
        address target = address(42);
        vm.assume(target.balance == 0);

        vm.deal(address(this), 1 ether);
        (bool succ,) = recipient.call{value: 1 ether}("");

        assertEq(target.balance, 1 ether);
    }
}
