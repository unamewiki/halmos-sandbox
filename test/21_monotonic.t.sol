// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
// import "forge-std/Test.sol";

contract Monotonic {
    function f(uint x) public pure returns (uint) {
        if(x < type(uint128).max)
            return x * 42;
        else return x;
    }

    function inv(uint a, uint b) public pure {
        require(b > a);
        assert(f(b) > f(a));
    }
}

