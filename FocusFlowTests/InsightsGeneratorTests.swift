//
//  InsightsGeneratorTests.swift
//  FocusFlowTests
//
//  Unit tests for InsightsGenerator
//

import XCTest
@testable import FocusFlow

final class InsightsGeneratorTests: XCTestCase {

    var generator: InsightsGenerator!

    override func setUp() {
        super.setUp()
        generator = InsightsGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    // MARK: - Empty Sessions Tests

    func testEmptySessionsReturnsNoInsights() {
        // Given: No sessions
        let sessions: [FocusSession] = []

        // When: Generating insights
        let insights = generator.generateInsights(from: sessions)

        // Then: Should return empty array
        XCTAssertTrue(insights.isEmpty, "No sessions should produce no insights")
    }

    // MARK: - Notification Impact Tests

    func testNotificationImpactDetected() {
        // Given: Sessions with varying notification counts
        let lowNotifSession = createSession(duration: 1500, notifications: 1, score: 0.8)
        let highNotifSession = createSession(duration: 1500, notifications: 10, score: 0.4)

        let sessions = [lowNotifSession, lowNotifSession, lowNotifSession,
                       highNotifSession, highNotifSession, highNotifSession]

        // When: Generating insights
        let insights = generator.generateInsights(from: sessions)

        // Then: Should detect notification impact
        let notificationInsights = insights.filter { $0.category == .notifications }
        XCTAssertFalse(notificationInsights.isEmpty, "Should detect notification impact")
    }

    // MARK: - Time of Day Tests

    func testTimeOfDayPatternDetected() {
        // Given: Sessions at specific hours
        let morningSessions = (0..<5).map { _ in
            createSession(duration: 1800, hour: 9, score: 0.85)
        }

        let eveningSessions = (0..<5).map { _ in
            createSession(duration: 1200, hour: 20, score: 0.55)
        }

        let sessions = morningSessions + eveningSessions

        // When: Generating insights
        let insights = generator.generateInsights(from: sessions)

        // Then: Should detect time of day pattern
        let timeInsights = insights.filter { $0.category == .timeOfDay }
        XCTAssertFalse(timeInsights.isEmpty, "Should detect time of day pattern")
    }

    // MARK: - App Switching Tests

    func testLowAppSwitchingRecognized() {
        // Given: Sessions with minimal app switching
        let sessions = (0..<5).map { _ in
            createSession(duration: 1800, appSwitches: 1, score: 0.85)
        }

        // When: Generating insights
        let insights = generator.generateInsights(from: sessions)

        // Then: Should recognize good behavior
        let switchingInsights = insights.filter { $0.category == .appSwitching }
        if let insight = switchingInsights.first {
            XCTAssertEqual(insight.impact, .positive, "Low switching should be positive")
        }
    }

    // MARK: - Helper Methods

    private func createSession(
        duration: Int = 1500,
        appSwitches: Int = 2,
        notifications: Int = 3,
        hour: Int = 9,
        dayOfWeek: Int = 1,
        score: Double = 0.7
    ) -> FocusSession {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0

        let startTime = calendar.date(from: components)!
        let endTime = startTime.addingTimeInterval(TimeInterval(duration))

        var session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: appSwitches,
            screenLockCount: 0,
            notificationCount: notifications
        )

        session.predictedCategory = session.computeGroundTruthLabel()
        session.focusScore = score

        return session
    }
}
