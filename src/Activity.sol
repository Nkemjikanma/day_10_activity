// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Activity {
    enum WorkoutType {
        Running,
        Cycling,
        HIIT
    }

    struct WorkoutSession {
        uint256 timestamp;
        WorkoutType workoutType;
        uint256 durationMinutes;
        uint256 caloriesBurned;
    }

    struct Goal {
        uint256 targetWorkoutsPerWeek; // Weekly workout target
        uint256 targetMinutesPerWeek; // Weekly duration target
        uint256 targetCaloriesPerWeek; // Weekly calorie burn target
        uint256 totalTargetWorkouts; // Lifetime workout target
        uint256 totalTargetMinutes; // Lifetime duration target
        uint256 totalTargetCalories; // Lifetime calorie burn target
    }

    // Weekly stats for tracking weekly progress
    struct WeeklyStats {
        uint256 weekStartTimestamp;
        uint256 workoutsCompleted;
        uint256 totalMinutes;
        uint256 totalCalories;
        bool weeklyWorkoutGoalMet;
        bool weeklyMinutesGoalMet;
        bool weeklyCaloriesGoalMet;
    }

    // Achievement struct to track user milestones
    struct Achievement {
        string name;
        string description;
        bool achieved;
        uint256 achievedTimestamp;
    }

    struct UserProfile {
        address userAddress;
        // Cumulative stats
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        // Goals
        Goal userGoals;
        //achievements
        mapping(uint256 => Achievement) achievements;
        uint256 achievementCount;
        // Array of workout session IDs
        uint256[] workoutSessionIds;
        // Active status
        bool isActive;
    }

    mapping(address => UserProfile) public userProfile;
    mapping(uint256 => WorkoutSession) public workoutSessions;
    uint256 private workoutSessionId;
}
