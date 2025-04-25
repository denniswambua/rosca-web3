// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Rosca} from "../contracts/Rosca.sol";

contract RoscaScript is Script {
    Rosca public rosca;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        rosca = new Rosca(3.156e7, 1e17);

        vm.stopBroadcast();
    }
}
