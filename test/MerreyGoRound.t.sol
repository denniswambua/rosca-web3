// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MerryGoRound} from "../contracts/MerryGoRound.sol";

contract MerryGoRoundTest is Test {
    MerryGoRound public merrygoround;
    uint256 constant DURATION_IN_SECONDS = 3.156e7; // one year
    uint256 constant MINIMUM_CONTRIBUTION = 1 ether;
    address owner;

    function setUp() public {
        owner = msg.sender;
        vm.prank(owner);
        merrygoround = new MerryGoRound(DURATION_IN_SECONDS, MINIMUM_CONTRIBUTION);
    }

    modifier activate() {
        assert(merrygoround.checkActive() == false);
        vm.deal(owner, MINIMUM_CONTRIBUTION);
        vm.prank(owner);
        merrygoround.activate{value: MINIMUM_CONTRIBUTION}();
        assert(merrygoround.checkActive() == true);
        _;
    }

    function test_can_join() public activate {

        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION}();

        vm.prank(member);
        uint256 member_balance = merrygoround.get_balance();

        assert(member_balance == MINIMUM_CONTRIBUTION);
    }

    function test_cannot_join_ifnot_active() public {
        
        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(MerryGoRound.MerryGoRound__Not_Active.selector);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION}();
    }

    function test_cannot_join_without_minimum_contribution() public activate {
        address member = address(1);
        vm.expectRevert(MerryGoRound.MerryGoRound__Contribution_Not_Enough.selector);
        merrygoround.join();
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(MerryGoRound.MerryGoRound__Contribution_Not_Enough.selector);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION - 1}();
    }

    function test_can_withdraw() public activate {
        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION}();

        vm.prank(member);
        uint256 member_balance = merrygoround.get_balance();
        assert(member_balance == MINIMUM_CONTRIBUTION);

        uint256 withdraw_amount = 1 gwei;
        vm.prank(member);
        merrygoround.withdraw(withdraw_amount);

        vm.prank(member);
        uint256 new_member_balance = merrygoround.get_balance();
        assert(member_balance - withdraw_amount == new_member_balance);
        assert(member.balance == withdraw_amount);
    }

    function test_payout() public activate {
        // Add four  new members
        for(uint160 i=1; i < 4+1; i++) {
            address member = address(i);
            vm.deal(member, MINIMUM_CONTRIBUTION);
            vm.prank(member);
            merrygoround.join{value: MINIMUM_CONTRIBUTION}();
        }

        // Assert contract has balance for the five members
        assert(address(merrygoround).balance == MINIMUM_CONTRIBUTION * 5);

        assert(owner == merrygoround.get_owner());
        address next_member = merrygoround.get_next_payout_member();
        vm.prank(owner);
        merrygoround.payout();

        // Check next member is not the same as the paid member
        assert(next_member != merrygoround.get_next_payout_member());


        // Check member has received all the contributions.
        vm.prank(next_member);
        uint256 next_member_balance = merrygoround.get_balance();
        assert(next_member_balance == MINIMUM_CONTRIBUTION * 5);
    }
}
