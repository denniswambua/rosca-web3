// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MerryGoRound} from "../contracts/MerryGoRound.sol";

contract MerryGoRoundTest is Test {
    MerryGoRound public merrygoround;
    uint256 constant DURATION_IN_SECONDS = 3.156e7;
    uint256 constant MINIMUM_CONTRIBUTION = 1e17;

    function setUp() public {
        merrygoround = new MerryGoRound(DURATION_IN_SECONDS, MINIMUM_CONTRIBUTION);
    }

    function test_cannot_join_if_locked() public {
        assert(merrygoround.checkOpen() == true);
        merrygoround.lock();
        assert(merrygoround.checkOpen() == false);

        address member = address(1);
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(MerryGoRound.MerryGoRound__Not_Open.selector);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION}();
    }

    function test_cannot_join_without_minimum_contribution() public {
        address member = address(1);
        vm.expectRevert(MerryGoRound.MerryGoRound__Amount_Is_Not_Enough.selector);
        merrygoround.join();
        vm.deal(member, MINIMUM_CONTRIBUTION);
        vm.expectRevert(MerryGoRound.MerryGoRound__Amount_Is_Not_Enough.selector);
        vm.prank(member);
        merrygoround.join{value: MINIMUM_CONTRIBUTION - 1}();
    }
}
