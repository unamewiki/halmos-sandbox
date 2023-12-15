// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Test} from "forge-std/Test.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

// from https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol
abstract contract ERC20Test is SymTest, Test {
    // erc20 token address
    address internal token;

    // token holders
    address[] internal holders;

    function setUp() public virtual;

    function _checkNoBackdoor(bytes4 selector, bytes memory args, address caller, address other) public virtual {
        // consider two arbitrary distinct accounts
        vm.assume(other != caller);

        // record their current balances
        uint256 oldBalanceOther = IERC20(token).balanceOf(other);

        uint256 oldAllowance = IERC20(token).allowance(other, caller);

        // consider an arbitrary function call to the token from the caller
        vm.prank(caller);
        (bool success,) = address(token).call(abi.encodePacked(selector, args));
        vm.assume(success);

        uint256 newBalanceOther = IERC20(token).balanceOf(other);

        // ensure that the caller cannot spend other' tokens without approvals
        if (newBalanceOther < oldBalanceOther) {
            assert(oldAllowance >= oldBalanceOther - newBalanceOther);
        }
    }

    function check_transfer(address sender, address receiver, address other, uint256 amount) public virtual {
        // consider other that are neither sender or receiver
        require(other != sender);
        require(other != receiver);

        // record their current balance
        uint256 oldBalanceSender = IERC20(token).balanceOf(sender);
        uint256 oldBalanceReceiver = IERC20(token).balanceOf(receiver);
        uint256 oldBalanceOther = IERC20(token).balanceOf(other);

        vm.prank(sender);
        IERC20(token).transfer(receiver, amount);

        if (sender != receiver) {
            assert(IERC20(token).balanceOf(sender) <= oldBalanceSender); // ensure no subtraction overflow
            assert(IERC20(token).balanceOf(sender) == oldBalanceSender - amount);
            assert(IERC20(token).balanceOf(receiver) >= oldBalanceReceiver); // ensure no addition overflow
            assert(IERC20(token).balanceOf(receiver) == oldBalanceReceiver + amount);
        } else {
            // sender and receiver may be the same
            assert(IERC20(token).balanceOf(sender) == oldBalanceSender);
            assert(IERC20(token).balanceOf(receiver) == oldBalanceReceiver);
        }
        // make sure other balance is not affected
        assert(IERC20(token).balanceOf(other) == oldBalanceOther);
    }

    function check_transferFrom(address caller, address from, address to, address other, uint256 amount)
        public
        virtual
    {
        require(other != from);
        require(other != to);

        uint256 oldBalanceFrom = IERC20(token).balanceOf(from);
        uint256 oldBalanceTo = IERC20(token).balanceOf(to);
        uint256 oldBalanceOther = IERC20(token).balanceOf(other);

        uint256 oldAllowance = IERC20(token).allowance(from, caller);

        vm.prank(caller);
        IERC20(token).transferFrom(from, to, amount);

        if (from != to) {
            assert(IERC20(token).balanceOf(from) <= oldBalanceFrom);
            assert(IERC20(token).balanceOf(from) == oldBalanceFrom - amount);
            assert(IERC20(token).balanceOf(to) >= oldBalanceTo);
            assert(IERC20(token).balanceOf(to) == oldBalanceTo + amount);

            assert(oldAllowance >= amount); // ensure allowance was enough
            assert(oldAllowance == type(uint256).max || IERC20(token).allowance(from, caller) == oldAllowance - amount); // allowance decreases if not max
        } else {
            assert(IERC20(token).balanceOf(from) == oldBalanceFrom);
            assert(IERC20(token).balanceOf(to) == oldBalanceTo);
        }
        assert(IERC20(token).balanceOf(other) == oldBalanceOther);
    }
}

contract TestVyperJumpTable is ERC20Test {
    // optimized vyper bytecode from https://gist.github.com/charles-cooper/c959c38deaa75339d204a51c5180e4ba
    function setUp() public override {
        bytes memory OPTIMIZED_CODESIZE =
            hex"5f3560e01c600561049a601b395f51600760078260ff16848460181c0260181c06028260081c61ffff1601601939505f51818160181c1460033611166100445761041d565b8060fe16361034826001160217610496578060081c61ffff16565b602080604052806040015f54815260015460208201528051806020830101601f825f03163682375050601f19601f825160200101169050810190506040f35b60208060405280604001600254815260035460208201528051806020830101601f825f03163682375050601f19601f825160200101169050810190506040f35b60045460405260206040f35b6004358060a01c6104965760405260056040516020525f5260405f205460605260206060f35b6004358060a01c610496576040526024358060a01c6104965760605260066040516020525f5260405f20806060516020525f5260405f2090505460805260206080f35b60075460405260206040f35b6004358060a01c610496576040526005336020525f5260405f208054602435808203828111610496579050905081555060056040516020525f5260405f2080546024358082018281106104965790509050815550604051337fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60243560605260206060a3600160605260206060f35b6004358060a01c610496576040526024358060a01c6104965760605260056040516020525f5260405f208054604435808203828111610496579050905081555060056060516020525f5260405f208054604435808201828110610496579050905081555060066040516020525f5260405f2080336020525f5260405f209050805460443580820382811161049657905090508155506060516040517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60443560805260206080a3600160805260206080f35b6004358060a01c610496576040526024356006336020525f5260405f20806040516020525f5260405f20905055604051337f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560243560605260206060a3600160605260206060f35b6004358060a01c610496576040526008543318610496576040511561049657600754602435808201828110610496579050905060075560056040516020525f5260405f20805460243580820182811061049657905090508155506040515f7fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60243560605260206060a3005b336040526004356060526103c6610421565b005b6004358060a01c6104965760a052600660a0516020525f5260405f2080336020525f5260405f2090508054602435808203828111610496579050905081555060a05160405260243560605261041b610421565b005b5f5ffd5b6040511561049657600754606051808203828111610496579050905060075560056040516020525f5260405f20805460605180820382811161049657905090508155505f6040517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60605160805260206080a3565b5f80fd1ab4049f0c18160ddd015305a9059cbb015f45313ce56700de0540c10f1903284595d89b41009e05dd62ed3e01104579cc679003c845095ea7b302c04542966c6803b42523b872dd01ee6570a0823100ea2506fdde03005f05";
        bytes memory OPTIMIZED_GAS =
            hex"5f3560e01c6002600c820660011b61055701601e395f51565b6306fdde038118610067573461055357602080604052806040015f54815260015460208201528051806020830101601f825f03163682375050601f19601f825160200101169050810190506040f35b63a9059cbb81186104da57604436103417610553576004358060a01c610553576040526005336020525f5260405f208054602435808203828111610553579050905081555060056040516020525f5260405f2080546024358082018281106105535790509050815550604051337fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60243560605260206060a3600160605260206060f36104da565b6395d89b41811861015f57346105535760208060405280604001600254815260035460208201528051806020830101601f825f03163682375050601f19601f825160200101169050810190506040f35b6340c10f1981186104da57604436103417610553576004358060a01c610553576040526008543318610553576040511561055357600754602435808201828110610553579050905060075560056040516020525f5260405f20805460243580820182811061055357905090508155506040515f7fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60243560605260206060a3006104da565b63313ce56781186104da57346105535760045460405260206040f36104da565b6370a08231811861025f57602436103417610553576004358060a01c6105535760405260056040516020525f5260405f205460605260206060f35b6318160ddd81186104da57346105535760075460405260206040f36104da565b63dd62ed3e81186104da57604436103417610553576004358060a01c610553576040526024358060a01c6105535760605260066040516020525f5260405f20806060516020525f5260405f2090505460805260206080f36104da565b6323b872dd81186104da57606436103417610553576004358060a01c610553576040526024358060a01c6105535760605260056040516020525f5260405f208054604435808203828111610553579050905081555060056060516020525f5260405f208054604435808201828110610553579050905081555060066040516020525f5260405f2080336020525f5260405f209050805460443580820382811161055357905090508155506060516040517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60443560805260206080a3600160805260206080f36104da565b63095ea7b381186104da57604436103417610553576004358060a01c610553576040526024356006336020525f5260405f20806040516020525f5260405f20905055604051337f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560243560605260206060a3600160605260206060f36104da565b6342966c68811861047057602436103417610553573360405260043560605261046e6104de565b005b6379cc679081186104da57604436103417610553576004358060a01c6105535760a052600660a0516020525f5260405f2080336020525f5260405f2090508054602435808203828111610553579050905081555060a0516040526024356060526104d86104de565b005b5f5ffd5b6040511561055357600754606051808203828111610553579050905060075560056040516020525f5260405f20805460605180820382811161055357905090508155505f6040517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60605160805260206080a3565b5f80fd04da022404da020404da02db027f00180447010f04da03c6";

        token = address(42);
        vm.etch(token, OPTIMIZED_GAS);
    }
}
