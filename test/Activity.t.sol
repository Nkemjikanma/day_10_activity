// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Activity} from "../src/Activity.sol";

contract CounterTest is Test {
    Activity public activity;

    function setUp() public {
        activity = new Activity();
    }

    function testRegistration() public {
        address user = makeAddr("user");

        Activity.Goal memory goal =
            Activity.Goal({targetWorkoutsPerWeek: 5, targetMinutesPerWeek: 150, targetCaloriesPerWeek: 10000});

        vm.prank(user);
        activity.userRegistration(goal);

        vm.prank(user);
        (uint256 workouts, uint256 mins, uint256 cals) = activity.getUserGoal();

        assertEq(workouts, 5);
        assertEq(mins, 150);
        assertEq(cals, 10000);
    }
}
