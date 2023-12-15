// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract Test12 is Test {
    /// test passes because data has a fixed size of 100
    /// @custom:halmos --array-length data=100
    function test_ArrayLength(bytes calldata data) external {
        assert(data.length != 42);
    }
}
