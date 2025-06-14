// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Activity {
    error Activity__UserAlreadyExists();
    error Activity__InvalidUser();
    error Activity__NotAuthorized();
    error Activity__SessionNotFound();
    error Activity__UnauthorizedAccess();

    uint256 private constant SECONDS_PER_WEEK = 7 * 24 * 60 * 60; // 7 days in seconds;

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
            // uint256 totalTargetWorkouts; // Lifetime workout target
            // uint256 totalTargetMinutes; // Lifetime duration target
            // uint256 totalTargetCalories; // Lifetime calorie burn target
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

    struct UserProfile {
        address userAddress;
        uint256 registrationTimestamp;
        // Cumulative stats
        uint256 totalWorkouts;
        uint256 totalMinutes;
        uint256 totalCalories;
        // Goals
        Goal userGoals;
        // Current week tracking
        WeeklyStats currentWeekStats;
        // Array of workout session IDs
        uint256[] workoutSessionIds;
        // Active status
        bool isActive;
    }

    mapping(address => UserProfile) public userProfile;
    mapping(uint256 => WorkoutSession) public workoutSessions;
    uint256 private workoutSessionId;

    // address - weekNumber - userWeeklyStats
    mapping(address => mapping(uint256 => WeeklyStats)) public userWeeklyStats;

    // address - session Id - isOwner
    mapping(address => mapping(uint256 => bool)) private sessionOwnership;

    event NewUserCreated(address indexed _user);
    event GoalUpdated(address indexed _user);
    event WeekCompleted(address indexed _user, uint256 _weekNumber, uint256 _workoutsCompleted, bool _weeklyGoalMet);
    event NewWeekStarted(address indexed _user, uint256 _time);
    event WorkoutLogged(address indexed _user, WorkoutType _workoutType, uint256 _sessionId, uint256 _time);

    modifier validateUser() {
        if (!userProfile[msg.sender].isActive) {
            revert Activity__InvalidUser();
        }

        if (userProfile[msg.sender].userAddress != msg.sender) {
            revert Activity__NotAuthorized();
        }
        _;
    }

    constructor() {}

    function userRegistration(Goal calldata _userGoal) public {
        if (userProfile[msg.sender].isActive) {
            revert Activity__UserAlreadyExists();
        }

        userProfile[msg.sender].userAddress = msg.sender;
        userProfile[msg.sender].registrationTimestamp = block.timestamp; // Store registration time
        userProfile[msg.sender].totalWorkouts = 0;
        userProfile[msg.sender].totalCalories = 0;
        userProfile[msg.sender].totalMinutes = 0;
        userProfile[msg.sender].userGoals.targetCaloriesPerWeek = _userGoal.targetCaloriesPerWeek;
        userProfile[msg.sender].userGoals.targetMinutesPerWeek = _userGoal.targetMinutesPerWeek;
        userProfile[msg.sender].userGoals.targetWorkoutsPerWeek = _userGoal.targetWorkoutsPerWeek;
        userProfile[msg.sender].isActive = true;

        emit NewUserCreated(msg.sender);
    }

    function updateGoal(Goal calldata _userGoal) public validateUser {
        userProfile[msg.sender].userGoals.targetCaloriesPerWeek = _userGoal.targetCaloriesPerWeek;
        userProfile[msg.sender].userGoals.targetMinutesPerWeek = _userGoal.targetMinutesPerWeek;
        userProfile[msg.sender].userGoals.targetWorkoutsPerWeek = _userGoal.targetWorkoutsPerWeek;

        emit GoalUpdated(msg.sender);
    }

    function logWorkout(WorkoutType _workoutType, uint256 _durationInMins, uint256 _caloriesBurned)
        public
        validateUser
    {
        uint256 _sessionId = workoutSessionId + 1;
        UserProfile storage currentUser = userProfile[msg.sender];

        // get week number based on registration time
        uint256 currentWeekNumber = (block.timestamp - currentUser.registrationTimestamp) / SECONDS_PER_WEEK + 1; // +1 so weeks start at 1 not 0

        // calculate what week the stored week starts are for
        uint256 storedWeekNumber = 0;
        if (currentUser.currentWeekStats.weekStartTimestamp > 0) {
            storedWeekNumber = (currentUser.currentWeekStats.weekStartTimestamp - currentUser.registrationTimestamp)
                / SECONDS_PER_WEEK + 1;
        }

        // iinitialize weekly starts if this is first workout
        if (storedWeekNumber != currentWeekNumber) {
            if (currentUser.currentWeekStats.weekStartTimestamp != 0) {
                // store current weeke details
                userWeeklyStats[msg.sender][storedWeekNumber] = currentUser.currentWeekStats;

                // Emit event that a week has completed
                emit WeekCompleted(
                    msg.sender,
                    storedWeekNumber,
                    currentUser.currentWeekStats.workoutsCompleted,
                    currentUser.currentWeekStats.weeklyWorkoutGoalMet
                );
            }

            // Initialize a new week
            currentUser.currentWeekStats.weekStartTimestamp = block.timestamp;
            currentUser.currentWeekStats.workoutsCompleted = 0;
            currentUser.currentWeekStats.totalMinutes = 0;
            currentUser.currentWeekStats.totalCalories = 0;
            currentUser.currentWeekStats.weeklyWorkoutGoalMet = false;
            currentUser.currentWeekStats.weeklyMinutesGoalMet = false;
            currentUser.currentWeekStats.weeklyCaloriesGoalMet = false;

            // Emit event for new week started
            emit NewWeekStarted(msg.sender, block.timestamp);
        }

        // updated current weekly stats
        currentUser.currentWeekStats.totalCalories += _caloriesBurned;
        currentUser.currentWeekStats.totalMinutes += _durationInMins;
        currentUser.currentWeekStats.workoutsCompleted += 1;

        if (
            !currentUser.currentWeekStats.weeklyWorkoutGoalMet
                && currentUser.currentWeekStats.workoutsCompleted >= currentUser.userGoals.targetWorkoutsPerWeek
        ) {
            currentUser.currentWeekStats.weeklyWorkoutGoalMet = true;
        }

        if (currentUser.currentWeekStats.totalMinutes >= currentUser.userGoals.targetMinutesPerWeek) {
            currentUser.currentWeekStats.weeklyMinutesGoalMet = true;
        }

        if (currentUser.currentWeekStats.totalCalories >= currentUser.userGoals.targetCaloriesPerWeek) {
            currentUser.currentWeekStats.weeklyCaloriesGoalMet = true;
        }

        // Update total stats
        currentUser.totalWorkouts += 1;
        currentUser.totalMinutes += _durationInMins;
        currentUser.totalCalories += _caloriesBurned;

        // Create and store the workout session
        workoutSessions[_sessionId] = WorkoutSession({
            timestamp: block.timestamp,
            workoutType: _workoutType,
            durationMinutes: _durationInMins,
            caloriesBurned: _caloriesBurned
        });

        currentUser.workoutSessionIds.push(_sessionId);
        sessionOwnership[msg.sender][_sessionId] = true;

        // Increment the session ID counter for next workout
        workoutSessionId = _sessionId;

        emit WorkoutLogged(msg.sender, _workoutType, _sessionId, block.timestamp);
    }

    function getWorkoutSession(uint256 _sessionId) public view validateUser returns (WorkoutSession memory) {
        // Verify the user owns this session
        if (!sessionOwnership[msg.sender][_sessionId]) {
            revert Activity__UnauthorizedAccess();
        }

        // Get the workout session
        WorkoutSession memory session = workoutSessions[_sessionId];

        // Verify the session exists
        if (session.timestamp == 0) {
            revert Activity__SessionNotFound();
        }

        return session;
    }

    function getUserWorkoutHistory() public view validateUser returns (uint256[] memory) {
        return userProfile[msg.sender].workoutSessionIds;
    }

    function getUserGoal() public view returns (uint256, uint256, uint256) {
        UserProfile storage user = userProfile[msg.sender];

        return (
            user.userGoals.targetWorkoutsPerWeek,
            user.userGoals.targetMinutesPerWeek,
            user.userGoals.targetCaloriesPerWeek
        );
    }
}
