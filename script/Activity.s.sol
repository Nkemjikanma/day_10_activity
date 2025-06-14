// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Activity} from "../src/Activity.sol";

contract ActivityScript is Script {
    Activity public activity;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        activity = new Activity();

        vm.stopBroadcast();
    }
}
