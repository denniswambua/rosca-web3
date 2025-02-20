// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MerryGoRound} from "../contracts/MerryGoRound.sol";

contract MerryGoRoundTest is Test {
    MerryGoRound public merrygoround;

    function setUp(){
        merrygoround = new MerryGoRound(3.156e7, 1e17);
    }
}
