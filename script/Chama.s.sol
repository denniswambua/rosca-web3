// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Chama} from "../src/Chama.sol";

contract ChamaScript is Script {
    Chama public chama;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        chama = new Chama(3.156e7, 1e17);

        vm.stopBroadcast();
    }
}
