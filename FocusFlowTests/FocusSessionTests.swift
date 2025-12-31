//
//  FocusSessionTests.swift
//  FocusFlowTests
//
//  Unit tests for FocusSession model
//

import XCTest
@testable import FocusFlow

final class FocusSessionTests: XCTestCase {

    // MARK: - Label Generation Tests

    func testDeepFocusLabel() {
        // Given: Long session with minimal interruptions
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1800) // 30 minutes

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 1,
            screenLockCount: 0,
            notificationCount: 2
        )

        // When: Computing label
        let label = session.computeGroundTruthLabel()

        // Then: Should be DeepFocus
        XCTAssertEqual(label, "DeepFocus", "Session with 30 min and 1 switch should be DeepFocus")
    }

    func testShallowFocusLabel() {
        // Given: Medium session
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(900) // 15 minutes

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 3,
            screenLockCount: 1,
            notificationCount: 4
        )

        // When: Computing label
        let label = session.computeGroundTruthLabel()

        // Then: Should be ShallowFocus
        XCTAssertEqual(label, "ShallowFocus", "Session with 15 min should be ShallowFocus")
    }

    func testDistractedLabelShortDuration() {
        // Given: Very short session
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(300) // 5 minutes

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 2,
            screenLockCount: 0,
            notificationCount: 1
        )

        // When: Computing label
        let label = session.computeGroundTruthLabel()

        // Then: Should be Distracted
        XCTAssertEqual(label, "Distracted", "Session with 5 min should be Distracted")
    }

    func testDistractedLabelHighSwitches() {
        // Given: Session with many app switches
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1200) // 20 minutes

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 10,
            screenLockCount: 2,
            notificationCount: 5
        )

        // When: Computing label
        let label = session.computeGroundTruthLabel()

        // Then: Should be Distracted
        XCTAssertEqual(label, "Distracted", "Session with 10 switches should be Distracted")
    }

    // MARK: - Focus Score Tests

    func testFocusScoreRange() {
        // Given: Any session
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1500)

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 3,
            screenLockCount: 1,
            notificationCount: 5
        )

        // When: Computing score
        let score = session.computeFocusScore()

        // Then: Score should be in valid range
        XCTAssertGreaterThanOrEqual(score, 0.0, "Score should be >= 0")
        XCTAssertLessThanOrEqual(score, 1.0, "Score should be <= 1")
    }

    func testHighQualitySessionScore() {
        // Given: Perfect session
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(2400) // 40 min

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 0,
            screenLockCount: 0,
            notificationCount: 0
        )

        // When: Computing score
        let score = session.computeFocusScore()

        // Then: Score should be high
        XCTAssertGreaterThan(score, 0.7, "Perfect session should have score > 0.7")
    }

    func testLowQualitySessionScore() {
        // Given: Distracted session
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(300) // 5 min

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 10,
            screenLockCount: 3,
            notificationCount: 8
        )

        // When: Computing score
        let score = session.computeFocusScore()

        // Then: Score should be low
        XCTAssertLessThan(score, 0.4, "Distracted session should have score < 0.4")
    }

    // MARK: - Time Features Tests

    func testStartHourExtraction() {
        // Given: Session at specific time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        components.minute = 30

        let startTime = calendar.date(from: components)!
        let endTime = startTime.addingTimeInterval(900)

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 2,
            screenLockCount: 0,
            notificationCount: 1
        )

        // Then: Hour should be extracted correctly
        XCTAssertEqual(session.startHour, 14, "Start hour should be 14 (2 PM)")
    }

    func testDayOfWeekExtraction() {
        // Given: Session on specific day
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) - 1 // Convert to 0-6

        let endTime = today.addingTimeInterval(900)

        let session = FocusSession(
            startTime: today,
            endTime: endTime,
            appSwitchCount: 2,
            screenLockCount: 0,
            notificationCount: 1
        )

        // Then: Day of week should match
        XCTAssertEqual(session.dayOfWeek, weekday, "Day of week should match")
    }

    // MARK: - Session Duration Tests

    func testSessionDurationCalculation() {
        // Given: Session with known duration
        let startTime = Date()
        let duration: TimeInterval = 1500 // 25 minutes
        let endTime = startTime.addingTimeInterval(duration)

        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: 1,
            screenLockCount: 0,
            notificationCount: 0
        )

        // Then: Duration should be calculated correctly
        XCTAssertEqual(session.sessionDuration, Int(duration), "Duration should be 1500 seconds")
    }
}
