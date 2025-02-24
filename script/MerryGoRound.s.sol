// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {MerryGoRound} from "../contracts/MerryGoRound.sol";

contract MerryGoRoundScript is Script {
    MerryGoRound public merrygoround;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        merrygoround = new MerryGoRound(3.156e7, 1e17);

        vm.stopBroadcast();
    }
}
