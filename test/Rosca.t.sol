// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {Rosca} from "../contracts/Rosca.sol";

contract RoscaTest is Test {
    Rosca public rosca;
    uint256 constant PERIOD_IN_SECONDS = 2.628e6; // one month
    uint256 constant MINIMUM_CONTRIBUTION = 1 ether;
    address owner;

    function setUp() public {
        owner = msg.sender;
        vm.prank(owner);
        rosca = new Rosca(PERIOD_IN_SECONDS, MINIMUM_CONTRIBUTION);
    }

    modifier activate() {
        assert(rosca.checkActive() == false);
        vm.deal(owner, MINIMUM_CONTRIBUTION);
        vm.prank(owner);
        rosca.activate{value: MINIMUM_CONTRIBUTION}();
        assert(rosca.checkActive() == true);
        assert(rosca.get_members_count() == 1);
        _;
    }

    function test_can_join() public activate {
        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.prank(member);
        rosca.join{value: MINIMUM_CONTRIBUTION}();

        vm.prank(member);
        uint256 member_balance = rosca.get_balance();

        assert(member_balance == MINIMUM_CONTRIBUTION);
    }

    function test_cannot_join_ifnot_active() public {
        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(Rosca.Rosca__Not_Active.selector);
        vm.prank(member);
        rosca.join{value: MINIMUM_CONTRIBUTION}();
    }

    function test_cannot_join_without_minimum_contribution() public activate {
        address member = address(1);
        vm.expectRevert(Rosca.Rosca__Contribution_Not_Enough.selector);
        rosca.join();
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(Rosca.Rosca__Contribution_Not_Enough.selector);
        vm.prank(member);
        rosca.join{value: MINIMUM_CONTRIBUTION - 1}();
    }

    function test_can_withdraw() public activate {
        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.prank(member);
        rosca.join{value: MINIMUM_CONTRIBUTION}();

        vm.prank(member);
        uint256 member_balance = rosca.get_balance();
        assert(member_balance == MINIMUM_CONTRIBUTION);

        uint256 withdraw_amount = 1 gwei;
        vm.prank(member);
        rosca.withdraw(withdraw_amount);

        vm.prank(member);
        uint256 new_member_balance = rosca.get_balance();
        assert(member_balance - withdraw_amount == new_member_balance);
        assert(member.balance == withdraw_amount);
    }

    modifier members_join() {
        // Add four  new members
        for (uint160 i = 1; i < 5; i++) {
            address member = address(i);
            vm.deal(member, MINIMUM_CONTRIBUTION);
            vm.prank(member);
            rosca.join{value: MINIMUM_CONTRIBUTION}();
        }
        assert(rosca.get_members_count() == 5);

        // Assert contract has balance for the five members
        assert(address(rosca).balance == MINIMUM_CONTRIBUTION * 5);
        _;
    }

    function test_payout() public activate members_join {
        // Check owner is the next member for payout
        assert(owner == rosca.get_owner());
        address next_member = rosca.get_next_payout_member();

        assert(owner == next_member);
        vm.prank(next_member);
        assert(rosca.get_balance() == MINIMUM_CONTRIBUTION);

        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS);
        rosca.payout();

        // Check next member is not the same as the paid member
        assert(next_member != rosca.get_next_payout_member());

        // Check member has received all the contributions.
        vm.prank(next_member);
        assert(rosca.get_balance() == MINIMUM_CONTRIBUTION * 5);
    }

    function test_payout_fail_owner_only() public activate {
        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS);
        vm.expectRevert(Rosca.Rosca__Not_Started_or_Cycle_Complete.selector);
        rosca.payout();
    }

    function test_payout_2_cycles() public activate members_join {
        address next_member = rosca.get_next_payout_member();
        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS);
        rosca.payout();

        //Member withdraws payout
        uint256 withdraw_amount = MINIMUM_CONTRIBUTION * 5;
        vm.prank(next_member);
        rosca.withdraw(withdraw_amount);

        assert(next_member.balance == withdraw_amount);

        // Owner deposits more funds
        vm.deal(owner, MINIMUM_CONTRIBUTION);
        vm.prank(owner);
        rosca.deposit{value: MINIMUM_CONTRIBUTION}();

        // four  members deposit more funds
        for (uint160 i = 1; i < 5; i++) {
            address member = address(i);
            vm.deal(member, MINIMUM_CONTRIBUTION);
            vm.prank(member);
            rosca.deposit{value: MINIMUM_CONTRIBUTION}();
        }

        // Assert contract has balance for the five members
        assert(address(rosca).balance == MINIMUM_CONTRIBUTION * 5);

        next_member = rosca.get_next_payout_member();

        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS + PERIOD_IN_SECONDS);
        rosca.payout();

        // Check member has received all the contributions.
        vm.prank(next_member);
        assert(rosca.get_balance() == MINIMUM_CONTRIBUTION * 5);
    }

    function test_payout_fails_when_one_member_hasnot_contributed() public activate members_join {
        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS);
        rosca.payout();

        // Owner deposits more funds
        vm.deal(owner, MINIMUM_CONTRIBUTION);
        vm.prank(owner);
        rosca.deposit{value: MINIMUM_CONTRIBUTION}();

        // two  members deposit more funds
        for (uint160 i = 1; i < 3; i++) {
            address member = address(i);
            vm.deal(member, MINIMUM_CONTRIBUTION);
            vm.prank(member);
            rosca.deposit{value: MINIMUM_CONTRIBUTION}();
        }

        // Assert contract has balance for the five members
        assert(address(rosca).balance == MINIMUM_CONTRIBUTION * 8);

        address next_member = rosca.get_next_payout_member();

        vm.prank(owner);
        vm.warp(block.timestamp + PERIOD_IN_SECONDS + PERIOD_IN_SECONDS);
        vm.expectRevert(Rosca.Rosca__Contribution_Not_Enough.selector);
        rosca.payout();

        // Payout didn't go through so next member should be the same.
        assert(next_member == rosca.get_next_payout_member());
    }

    function test_payout_fails_before_period() public activate members_join {
        vm.prank(owner);
        vm.expectRevert(Rosca.Rosca__Payout_Not_Open.selector);
        rosca.payout();
    }
}
