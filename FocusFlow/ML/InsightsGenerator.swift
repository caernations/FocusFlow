import Foundation

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: InsightCategory
    let impact: InsightImpact

    enum InsightCategory {
        case timeOfDay
        case notifications
        case sessionPattern
        case weekdayVsWeekend
        case appSwitching
    }

    enum InsightImpact {
        case positive
        case neutral
        case negative
    }
}

class InsightsGenerator {

    /// Generate insights from focus sessions
    func generateInsights(from sessions: [FocusSession]) -> [Insight] {
        guard !sessions.isEmpty else { return [] }

        var insights: [Insight] = []

        // Analyze time-of-day patterns
        if let timeInsight = analyzeTimeOfDay(sessions: sessions) {
            insights.append(timeInsight)
        }

        // Analyze notification impact
        if let notificationInsight = analyzeNotificationImpact(sessions: sessions) {
            insights.append(notificationInsight)
        }

        // Analyze app switching behavior
        if let appSwitchInsight = analyzeAppSwitching(sessions: sessions) {
            insights.append(appSwitchInsight)
        }

        // Analyze weekday vs weekend patterns
        if let weekdayInsight = analyzeWeekdayPatterns(sessions: sessions) {
            insights.append(weekdayInsight)
        }

        // Analyze session duration trends
        if let durationInsight = analyzeDurationTrends(sessions: sessions) {
            insights.append(durationInsight)
        }

        return insights
    }

    // MARK: - Analysis Functions

    /// Analyze which hours yield best focus
    private func analyzeTimeOfDay(sessions: [FocusSession]) -> Insight? {
        // Group sessions by hour
        var hourlyScores: [Int: [Double]] = [:]

        for session in sessions {
            guard let score = session.focusScore else { continue }
            hourlyScores[session.startHour, default: []].append(score)
        }

        // Find best performing hours (need at least 2 sessions)
        let hourAverages = hourlyScores
            .filter { $0.value.count >= 2 }
            .mapValues { scores in scores.reduce(0, +) / Double(scores.count) }

        guard let bestHour = hourAverages.max(by: { $0.value < $1.value }) else {
            return nil
        }

        let avgScore = bestHour.value

        // Generate time range (e.g., 9-11 AM)
        let startHour = bestHour.key
        let endHour = min(startHour + 2, 23)
        let timeRange = formatHourRange(start: startHour, end: endHour)

        let description = String(format:
            "You achieve your best focus during %@, with an average focus score of %.0f%%. Consider scheduling important work during this time.",
            timeRange, avgScore * 100
        )

        return Insight(
            title: "Peak Focus Hours",
            description: description,
            category: .timeOfDay,
            impact: .positive
        )
    }

    /// Analyze notification impact on focus
    private func analyzeNotificationImpact(sessions: [FocusSession]) -> Insight? {
        let lowNotificationSessions = sessions.filter { $0.notificationCount <= 2 }
        let highNotificationSessions = sessions.filter { $0.notificationCount > 5 }

        guard lowNotificationSessions.count >= 3,
              highNotificationSessions.count >= 3 else {
            return nil
        }

        let lowNotifAvgScore = lowNotificationSessions.compactMap { $0.focusScore }.reduce(0, +) / Double(lowNotificationSessions.count)
        let highNotifAvgScore = highNotificationSessions.compactMap { $0.focusScore }.reduce(0, +) / Double(highNotificationSessions.count)

        let scoreDrop = (lowNotifAvgScore - highNotifAvgScore) / lowNotifAvgScore

        guard scoreDrop > 0.15 else {
            return Insight(
                title: "Notification Handling",
                description: "Great job! Notifications don't seem to significantly impact your focus. Keep it up!",
                category: .notifications,
                impact: .positive
            )
        }

        let description = String(format:
            "Notifications reduce your focus score by %.0f%%. Try enabling Do Not Disturb during focus sessions.",
            scoreDrop * 100
        )

        return Insight(
            title: "Notification Impact",
            description: description,
            category: .notifications,
            impact: .negative
        )
    }

    /// Analyze app switching patterns
    private func analyzeAppSwitching(sessions: [FocusSession]) -> Insight? {
        let avgSwitches = sessions.map { Double($0.appSwitchCount) }.reduce(0, +) / Double(sessions.count)

        let deepFocusSessions = sessions.filter { $0.predictedCategory == "DeepFocus" }

        if avgSwitches < 2.0 {
            return Insight(
                title: "Excellent Focus Discipline",
                description: "You average only \(Int(avgSwitches)) app switches per session. This shows strong focus discipline!",
                category: .appSwitching,
                impact: .positive
            )
        } else if avgSwitches > 5.0 {
            let description = String(format:
                "You average %.0f app switches per session. Try using app blockers or Focus Mode to reduce distractions.",
                avgSwitches
            )
            return Insight(
                title: "High App Switching",
                description: description,
                category: .appSwitching,
                impact: .negative
            )
        }

        return nil
    }

    /// Analyze weekday vs weekend patterns
    private func analyzeWeekdayPatterns(sessions: [FocusSession]) -> Insight? {
        let weekdaySessions = sessions.filter { (1...5).contains($0.dayOfWeek) }
        let weekendSessions = sessions.filter { [0, 6].contains($0.dayOfWeek) }

        guard weekdaySessions.count >= 5,
              weekendSessions.count >= 2 else {
            return nil
        }

        let weekdayAvgScore = weekdaySessions.compactMap { $0.focusScore }.reduce(0, +) / Double(weekdaySessions.count)
        let weekendAvgScore = weekendSessions.compactMap { $0.focusScore }.reduce(0, +) / Double(weekendSessions.count)

        let difference = weekendAvgScore - weekdayAvgScore

        if difference > 0.1 {
            return Insight(
                title: "Weekend Warrior",
                description: "Your focus is \(Int(difference * 100))% better on weekends. Consider replicating weekend conditions on weekdays.",
                category: .weekdayVsWeekend,
                impact: .positive
            )
        } else if difference < -0.1 {
            return Insight(
                title: "Weekday Peak Performer",
                description: "You focus better during weekdays. Your work routine seems to support deep work!",
                category: .weekdayVsWeekend,
                impact: .positive
            )
        }

        return nil
    }

    /// Analyze session duration trends
    private func analyzeDurationTrends(sessions: [FocusSession]) -> Insight? {
        let avgDuration = sessions.map { $0.sessionDuration }.reduce(0, +) / sessions.count

        if avgDuration > 1500 {
            return Insight(
                title: "Marathon Focus Sessions",
                description: "Your average session lasts \(avgDuration / 60) minutes. Consider taking breaks to avoid burnout.",
                category: .sessionPattern,
                impact: .neutral
            )
        } else if avgDuration < 600 {
            return Insight(
                title: "Short Sessions",
                description: "Your sessions average \(avgDuration / 60) minutes. Try gradually increasing session length to 25+ minutes.",
                category: .sessionPattern,
                impact: .neutral
            )
        }

        return nil
    }

    // MARK: - Helper Functions

    /// Format hour range as human-readable string
    private func formatHourRange(start: Int, end: Int) -> String {
        func formatHour(_ hour: Int) -> String {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return "\(displayHour) \(period)"
        }

        return "\(formatHour(start))–\(formatHour(end))"
    }
}
