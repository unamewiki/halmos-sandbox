// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

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

contract Handler is Test {
    Owned owned;

    constructor(Owned _owned) {
        owned = _owned;
    }

    function transferOwnership(address sender, address candidate) external {
        vm.assume(sender != address(0));
        vm.prank(sender);
        owned.transferOwnership(candidate);
    }

    function acceptOwnership(address sender) external {
        vm.assume(sender != address(0));
        vm.prank(sender);
        owned.acceptOwnership();
    }
}

contract TwoStepOwnershipTest is Test {
    address owner;
    Owned owned;
    Handler handler;

    function setUp() public {
        owner = address(this);
        owned = new Owned();

        handler = new Handler(owned);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.transferOwnership.selector;
        selectors[1] = Handler.acceptOwnership.selector;
        targetSelector(FuzzSelector(address(handler), selectors));
    }

    function test_successful_transfer(address newOwner) public {
        handler.transferOwnership(owner, newOwner);
        handler.acceptOwnership(newOwner);

        assertEq(owned.owner(), newOwner);
    }

    function invariant_owner_never_changes_this_is_bad_lol() public returns(bool cond) {
        cond = (owned.owner() == owner);
        assertEq(owned.owner(), owner);
    }


    function bad_inductive_invariant() public view returns(bool) {
        return owned.owner() == owner;
    }

    function check_bad_inductive_invariant(bytes memory call_data, address sender, uint256 msg_value) public {
        assertTrue(bad_inductive_invariant());

        vm.deal(sender, msg_value);
        vm.prank(sender);
        address(owned).call{value: msg_value}(call_data);

        assertTrue(bad_inductive_invariant());
    }
}
