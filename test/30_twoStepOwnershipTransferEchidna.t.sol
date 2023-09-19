// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Owned {
    address public owner;
    address private ownerCandidate;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerCandidate() {
        require(msg.sender == ownerCandidate);
        _;
    }

   function transferOwnership(address candidate) external onlyOwner {
        ownerCandidate = candidate;
    }

    function acceptOwnership() external onlyOwnerCandidate {
        owner = ownerCandidate;
    }
}

contract TestOwned is Owned {
    address private initialOwner;

    constructor() {
        initialOwner = msg.sender;
    }

    function echidna_invariant_owner_never_changes_this_is_bad_lol() public view returns(bool) {
        return owner == initialOwner;
    }
}
