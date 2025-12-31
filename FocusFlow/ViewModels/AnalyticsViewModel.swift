import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sessions: [FocusSession] = []
    @Published var selectedTimeRange: TimeRange = .week
    @Published var isLoading = false

    // Computed analytics
    @Published var totalSessions = 0
    @Published var averageFocusScore: Double = 0.0
    @Published var totalFocusTime: TimeInterval = 0
    @Published var categoryDistribution: [String: Int] = [:]

    // MARK: - Private Properties
    private let persistence = PersistenceManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All Time"

        var id: String { rawValue }

        func dateRange(from currentDate: Date = Date()) -> (start: Date, end: Date) {
            let calendar = Calendar.current
            let endDate = currentDate

            switch self {
            case .today:
                return (currentDate.startOfDay, currentDate.endOfDay)
            case .week:
                let startDate = calendar.date(byAdding: .day, value: -7, to: currentDate)!
                return (startDate, endDate)
            case .month:
                let startDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
                return (startDate, endDate)
            case .all:
                let startDate = calendar.date(byAdding: .year, value: -10, to: currentDate)!
                return (startDate, endDate)
            }
        }
    }

    // MARK: - Initialization
    init() {
        loadSessions()
    }

    // MARK: - Data Loading

    func loadSessions() {
        isLoading = true

        let range = selectedTimeRange.dateRange()
        sessions = persistence.fetchSessions(from: range.start, to: range.end)

        // Compute analytics
        computeAnalytics()

        isLoading = false
    }

    func refresh() {
        loadSessions()
    }

    // MARK: - Analytics Computation

    private func computeAnalytics() {
        totalSessions = sessions.count

        // Average focus score
        let scores = sessions.compactMap { $0.focusScore }
        averageFocusScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)

        // Total focus time
        totalFocusTime = sessions.map { TimeInterval($0.sessionDuration) }.reduce(0, +)

        // Category distribution
        var distribution: [String: Int] = [
            "DeepFocus": 0,
            "ShallowFocus": 0,
            "Distracted": 0
        ]

        for session in sessions {
            if let category = session.predictedCategory {
                distribution[category, default: 0] += 1
            }
        }

        categoryDistribution = distribution
    }

    // MARK: - Chart Data

    /// Get daily focus scores for line chart
    func getDailyFocusScores() -> [(date: Date, score: Double)] {
        let calendar = Calendar.current
        var dailyScores: [Date: [Double]] = [:]

        for session in sessions {
            let dayStart = session.startTime.startOfDay
            dailyScores[dayStart, default: []].append(session.focusScore ?? 0.0)
        }

        return dailyScores
            .map { (date: $0.key, score: $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }
    }

    /// Get hourly distribution for bar chart
    func getHourlyDistribution() -> [(hour: Int, count: Int)] {
        var hourCounts: [Int: Int] = [:]

        for session in sessions {
            hourCounts[session.startHour, default: 0] += 1
        }

        return (0...23).map { hour in
            (hour: hour, count: hourCounts[hour] ?? 0)
        }
    }

    /// Get category breakdown percentages
    func getCategoryPercentages() -> [(category: String, percentage: Double)] {
        guard totalSessions > 0 else { return [] }

        return categoryDistribution.map { category, count in
            (category: category, percentage: Double(count) / Double(totalSessions))
        }.sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Filtered Sessions

    /// Get top performing sessions
    func getTopSessions(limit: Int = 5) -> [FocusSession] {
        return sessions
            .sorted { ($0.focusScore ?? 0) > ($1.focusScore ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    /// Get sessions by category
    func getSessions(by category: String) -> [FocusSession] {
        return sessions.filter { $0.predictedCategory == category }
    }
}
