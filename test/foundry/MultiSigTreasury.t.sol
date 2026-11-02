// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Multi-Sig-Key.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MOCK") { _mint(msg.sender, 1000); }
}

/// Tests whose names start with test_KnownIssue pin current behaviour that is a defect.
contract MultiSigTreasuryTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    address dave = makeAddr("dave");
    MultiSigTreasury t;

    function setUp() public {
        vm.startPrank(alice);
        t = new MultiSigTreasury(3, 2, "uri");
        t.safeTransferFrom(alice, bob, 1, 1, "");
        t.safeTransferFrom(alice, carol, 2, 1, "");
        vm.stopPrank();
        vm.deal(address(t), 5 ether);
    }

    function propose(uint amount, address to, address token) internal {
        uint[] memory a = new uint[](1);
        a[0] = amount;
        address[] memory addrs = new address[](token == address(0) ? 1 : 2);
        addrs[0] = to;
        if (token != address(0)) addrs[1] = token;
        string[] memory s = new string[](3);
        s[0] = "topic";
        s[1] = "message";
        s[2] = "";
        vm.prank(alice);
        t.submitProposal(a, addrs, s);
    }

    function vote(address who, uint key, bool yes) internal {
        vm.prank(who);
        t.confirmTransaction(0, yes, key);
    }

    function test_TwoOfThreeVotesReleaseXdc() public {
        propose(1 ether, dave, address(0));
        vote(alice, 0, true);
        assertEq(dave.balance, 0);
        vote(bob, 1, true);
        assertEq(dave.balance, 1 ether);
    }

    function test_EnoughNoVotesCloseTheProposal() public {
        propose(1 ether, dave, address(0));
        vote(alice, 0, false);
        vote(bob, 1, false);
        assertEq(dave.balance, 0);
        vm.prank(carol);
        vm.expectRevert();
        t.confirmTransaction(0, true, 2);
    }

    function test_AKeyCannotVoteTwice() public {
        propose(1 ether, dave, address(0));
        vote(alice, 0, true);
        vm.prank(alice);
        vm.expectRevert("vote has been cast already");
        t.confirmTransaction(0, true, 0);
    }

    function test_RevokedVoteNoLongerCounts() public {
        propose(1 ether, dave, address(0));
        vote(alice, 0, true);
        vm.prank(alice);
        t.revokeConfirmation(0, 0);
        vote(bob, 1, true);
        assertEq(dave.balance, 0);
    }

    function test_NonKeyHolderCannotPropose() public {
        uint[] memory a = new uint[](1);
        address[] memory addrs = new address[](1);
        string[] memory s = new string[](3);
        vm.prank(dave);
        vm.expectRevert("You must hold a Key to access this function");
        t.submitProposal(a, addrs, s);
    }

    function test_KnownIssue_TwoTopicStringsRevert() public {
        uint[] memory a = new uint[](1);
        address[] memory addrs = new address[](1);
        string[] memory s = new string[](2);
        vm.prank(alice);
        vm.expectRevert();
        t.submitProposal(a, addrs, s);
    }

    function test_KnownIssue_PassedTokenProposalMovesNothing() public {
        MockToken token = new MockToken();
        token.transfer(address(t), 100);
        propose(40, dave, address(token));
        vote(alice, 0, true);
        vote(bob, 1, true);
        vm.prank(alice);
        assertTrue(t.checkTransactionStatus(0));
        assertEq(token.balanceOf(dave), 0);
        assertEq(token.balanceOf(address(t)), 100);
    }
}
