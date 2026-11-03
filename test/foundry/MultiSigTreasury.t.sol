// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Multi-Sig-Key.sol";
import "../../contracts/Tokens.sol";

contract Rejector {
    receive() external payable { revert("no thanks"); }
}

/// Tries to vote again while being paid.
contract ReentrantVoter {
    MultiSigTreasury treasury;
    uint key;
    bool public attempted;
    bool public reentered;

    function arm(MultiSigTreasury _treasury, uint _key) external {
        treasury = _treasury;
        key = _key;
    }

    receive() external payable {
        attempted = true;
        try treasury.confirmTransaction(1, true, key) {
            reentered = true;
        } catch {}
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

contract Counter {
    uint public count;
    function bump(uint by) external payable { count += by; }
    function fail() external pure { revert("nope"); }
}

contract NotAToken {}

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

    function topics() internal pure returns (string[] memory s) {
        s = new string[](2);
        s[0] = "topic";
        s[1] = "message";
    }

    function propose(uint[] memory a, address[] memory addrs) internal {
        vm.prank(alice);
        assertTrue(t.submitProposal(a, addrs, topics()));
    }

    function proposeXdc(uint amount, address to) internal {
        uint[] memory a = new uint[](1);
        a[0] = amount;
        address[] memory addrs = new address[](1);
        addrs[0] = to;
        propose(a, addrs);
    }

    function proposeToken(address token, address to, uint amount) internal {
        uint[] memory a = new uint[](1);
        a[0] = amount;
        address[] memory addrs = new address[](2);
        addrs[0] = to;
        addrs[1] = token;
        propose(a, addrs);
    }

    function proposeNft(address token, address to, uint amount, uint id) internal {
        uint[] memory a = new uint[](2);
        a[0] = amount;
        a[1] = id;
        address[] memory addrs = new address[](2);
        addrs[0] = to;
        addrs[1] = token;
        propose(a, addrs);
    }

    function vote(uint number, address who, uint key, bool yes) internal {
        vm.prank(who);
        t.confirmTransaction(number, yes, key);
    }

    function passVotes(uint number) internal {
        vote(number, alice, 0, true);
        vote(number, bob, 1, true);
    }

    function test_ConstructorRejectsBadThresholds() public {
        vm.expectRevert("you must create at least one key");
        new MultiSigTreasury(0, 0, "uri");
        vm.expectRevert("you must need at least one vote");
        new MultiSigTreasury(1, 0, "uri");
        vm.expectRevert("you cant have more votes needed than keys created");
        new MultiSigTreasury(1, 2, "uri");
    }

    function test_TwoOfThreeVotesReleaseXdc() public {
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, true);
        assertEq(dave.balance, 0);
        vote(0, bob, 1, true);
        assertEq(dave.balance, 1 ether);
        vm.prank(alice);
        assertTrue(t.checkTransactionExecuted(0));
    }

    function test_PlainVoteClosesWithoutPayment() public {
        proposeXdc(0, address(0));
        uint before = address(t).balance;
        passVotes(0);
        assertEq(address(t).balance, before);
        vm.prank(alice);
        assertTrue(t.checkTransactionExecuted(0));
    }

    function test_ThreeTopicStringsStillWork() public {
        uint[] memory a = new uint[](1);
        a[0] = 1 ether;
        address[] memory addrs = new address[](1);
        addrs[0] = dave;
        string[] memory s = new string[](3);
        vm.prank(alice);
        assertTrue(t.submitProposal(a, addrs, s));
    }

    function test_XRC20ProposalPaysTheRecipient() public {
        XRC20 token = new XRC20(1000);
        token.transfer(address(t), 100);
        proposeToken(address(token), dave, 40);
        passVotes(0);
        assertEq(token.balanceOf(dave), 40);
        assertEq(token.balanceOf(address(t)), 60);
    }

    function test_XRC20ProposalNeedsTheBalance() public {
        XRC20 token = new XRC20(1000);
        uint[] memory a = new uint[](1);
        a[0] = 1;
        address[] memory addrs = new address[](2);
        addrs[0] = dave;
        addrs[1] = address(token);
        vm.prank(alice);
        vm.expectRevert("Not enough XRC funds in contract");
        t.submitProposal(a, addrs, topics());
    }

    function test_XRC721ProposalPaysTheRecipient() public {
        XRC721 nft = new XRC721();
        uint id = nft.awardItem(address(t), "uri");
        proposeNft(address(nft), dave, 1, id);
        passVotes(0);
        assertEq(nft.ownerOf(id), dave);
    }

    function test_XRC1155ProposalPaysTheRecipient() public {
        vm.prank(alice);
        XRC1155 multi = new XRC1155();
        vm.prank(alice);
        multi.safeTransferFrom(alice, address(t), 1, 100, "");
        proposeNft(address(multi), dave, 30, 1);
        passVotes(0);
        assertEq(multi.balanceOf(dave, 1), 30);
        assertEq(multi.balanceOf(address(t), 1), 70);
    }

    function test_NftProposalForAnUnknownTokenRevertsAndStaysOpen() public {
        NotAToken bad = new NotAToken();
        proposeNft(address(bad), dave, 1, 1);
        vote(0, alice, 0, true);
        vm.prank(bob);
        vm.expectRevert("Token is not XRC721 or XRC1155");
        t.confirmTransaction(0, true, 1);
        vm.prank(alice);
        assertFalse(t.checkTransactionStatus(0));
    }

    function test_CallProposalCallsTheTargetWithValue() public {
        Counter counter = new Counter();
        vm.prank(alice);
        t.submitCallProposal(address(counter), 1 ether, abi.encodeCall(Counter.bump, (7)), "topic", "message");
        passVotes(0);
        assertEq(counter.count(), 7);
        assertEq(address(counter).balance, 1 ether);
    }

    function test_FailedCallRevertsTheDecidingVote() public {
        Counter counter = new Counter();
        vm.prank(alice);
        t.submitCallProposal(address(counter), 0, abi.encodeCall(Counter.fail, ()), "topic", "message");
        vote(0, alice, 0, true);
        vm.prank(bob);
        vm.expectRevert("Function call failed");
        t.confirmTransaction(0, true, 1);
        vm.prank(alice);
        assertFalse(t.checkTransactionExecuted(0));
    }

    function test_FailedPayoutRevertsTheDecidingVote() public {
        Rejector r = new Rejector();
        proposeXdc(1 ether, address(r));
        vote(0, alice, 0, true);
        vm.prank(bob);
        vm.expectRevert("XDC payment failed");
        t.confirmTransaction(0, true, 1);
        (, , bool counted) = viewVote(1, 0);
        assertFalse(counted);
    }

    function viewVote(uint key, uint number) internal returns (uint, bool, bool) {
        vm.prank(bob);
        return t.checkVote(key, number);
    }

    function test_ReentrantRecipientCannotVoteDuringPayout() public {
        ReentrantVoter attacker = new ReentrantVoter();
        vm.prank(carol);
        t.safeTransferFrom(carol, address(attacker), 2, 1, "");
        attacker.arm(t, 2);
        proposeXdc(1 ether, address(attacker));
        proposeXdc(1 ether, dave);
        passVotes(0);
        assertTrue(attacker.attempted());
        assertFalse(attacker.reentered());
        assertEq(address(attacker).balance, 1 ether);
        assertEq(dave.balance, 0);
    }

    function test_CannotVoteOnAProposalThatDoesNotExist() public {
        vm.prank(alice);
        vm.expectRevert("Proposal does not exist");
        t.confirmTransaction(0, true, 0);
    }

    function test_NoVotesOnlyCloseOnceThePassIsImpossible() public {
        vm.startPrank(alice);
        MultiSigTreasury five = new MultiSigTreasury(5, 2, "uri");
        five.safeTransferFrom(alice, bob, 1, 1, "");
        five.safeTransferFrom(alice, carol, 2, 1, "");
        five.safeTransferFrom(alice, dave, 3, 1, "");
        uint[] memory a = new uint[](1);
        address[] memory addrs = new address[](1);
        five.submitProposal(a, addrs, topics());
        five.confirmTransaction(0, false, 0);
        vm.stopPrank();
        vm.prank(bob);
        five.confirmTransaction(0, false, 1);
        vm.prank(alice);
        assertFalse(five.checkTransactionStatus(0)); // 3 keys could still pass it
        vm.prank(carol);
        five.confirmTransaction(0, false, 2);
        vm.prank(alice);
        assertFalse(five.checkTransactionStatus(0)); // 2 keys could still pass it
        vm.prank(dave);
        five.confirmTransaction(0, false, 3);
        vm.prank(alice);
        assertTrue(five.checkTransactionStatus(0));
        assertFalse(viewExecuted(five));
    }

    function viewExecuted(MultiSigTreasury five) internal returns (bool) {
        vm.prank(alice);
        return five.checkTransactionExecuted(0);
    }

    function test_ClosedProposalRefusesFurtherVotes() public {
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, false);
        vote(0, bob, 1, false);
        assertEq(dave.balance, 0);
        vm.prank(carol);
        vm.expectRevert("Contract Transaction Completed...no futher confrimation votes can be cast");
        t.confirmTransaction(0, true, 2);
    }

    function test_AKeyCannotVoteTwice() public {
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, true);
        vm.prank(alice);
        vm.expectRevert("vote has been cast already");
        t.confirmTransaction(0, true, 0);
    }

    function test_AHolderOfSeveralKeysCanVoteWithEach() public {
        vm.prank(bob);
        t.safeTransferFrom(bob, alice, 1, 1, "");
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, true);
        vote(0, alice, 1, true);
        assertEq(dave.balance, 1 ether);
    }

    function test_CannotVoteWithAKeyYouDoNotHold() public {
        proposeXdc(1 ether, dave);
        vm.prank(alice);
        vm.expectRevert("you must be the holder of the key");
        t.confirmTransaction(0, true, 1);
    }

    function test_TransferringAKeyDoesNotAllowASecondVote() public {
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, false);
        vm.prank(alice);
        t.safeTransferFrom(alice, dave, 0, 1, "");
        vm.prank(dave);
        vm.expectRevert("vote has been cast already");
        t.confirmTransaction(0, true, 0);
    }

    function test_RevokedVoteNoLongerCounts() public {
        proposeXdc(1 ether, dave);
        vote(0, alice, 0, true);
        vm.prank(alice);
        t.revokeConfirmation(0, 0);
        vote(0, bob, 1, true);
        assertEq(dave.balance, 0);
    }

    function test_NonKeyHolderCannotPropose() public {
        uint[] memory a = new uint[](1);
        address[] memory addrs = new address[](1);
        vm.prank(dave);
        vm.expectRevert("You must hold a Key to access this function");
        t.submitProposal(a, addrs, topics());
        vm.prank(dave);
        vm.expectRevert("You must hold a Key to access this function");
        t.submitCallProposal(dave, 0, "", "t", "m");
    }

    function testFuzz_TreasuryNeverPaysMoreThanApproved(uint96 balance, uint96 amount) public {
        vm.deal(address(t), balance);
        amount = uint96(bound(amount, 0, balance));
        proposeXdc(amount, dave);
        passVotes(0);
        assertEq(dave.balance, amount);
        assertEq(address(t).balance, uint(balance) - amount);
    }
}
