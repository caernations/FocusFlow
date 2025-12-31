import Foundation
import AppIntents

// MARK: - Start Focus Session Intent

@available(iOS 16.0, *)
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Start a new focus session in FocusFlow")

    @Parameter(title: "Duration (minutes)", default: 25)
    var duration: Int

    func perform() async throws -> some IntentResult {
        // In a real app, you'd communicate with the app to start the timer
        // For now, just return success
        return .result(dialog: "Starting \(duration)-minute focus session in FocusFlow!")
    }
}

// MARK: - Get Today's Stats Intent

@available(iOS 16.0, *)
struct GetTodayStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Focus Stats"
    static var description = IntentDescription("Show your focus statistics for today")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let persistence = PersistenceManager.shared

        // Get today's sessions
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let sessions = persistence.fetchSessions(from: startOfDay, to: endOfDay)

        let totalSessions = sessions.count
        let totalMinutes = sessions.map { $0.sessionDuration }.reduce(0, +) / 60
        let avgScore = sessions.compactMap { $0.focusScore }.reduce(0.0, +) / Double(max(sessions.count, 1))

        let message = """
        Today's Focus Stats:
        • Sessions: \(totalSessions)
        • Total Time: \(totalMinutes) minutes
        • Avg Score: \(Int(avgScore * 100))%
        """

        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct FocusFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Begin focus session in \(.applicationName)",
                "Start \(.applicationName) timer"
            ],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: GetTodayStatsIntent(),
            phrases: [
                "Show my focus stats in \(.applicationName)",
                "How productive was I in \(.applicationName)",
                "Get my \(.applicationName) stats"
            ],
            shortTitle: "Today's Stats",
            systemImageName: "chart.bar"
        )
    }
}
