import Foundation
import SwiftUI
import Combine

@MainActor
class InsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var insights: [Insight] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private let persistence = PersistenceManager.shared
    private let insightsGenerator = InsightsGenerator()

    // MARK: - Initialization
    init() {
        loadInsights()
    }

    // MARK: - Data Loading

    func loadInsights() {
        isLoading = true

        // Fetch all sessions (or recent sessions)
        let sessions = persistence.fetchAllSessions()

        // Generate insights
        insights = insightsGenerator.generateInsights(from: sessions)

        isLoading = false
    }

    func refresh() {
        loadInsights()
    }

    // MARK: - Filtered Insights

    /// Get insights by category
    func getInsights(by category: Insight.InsightCategory) -> [Insight] {
        return insights.filter { $0.category == category }
    }

    /// Get positive insights
    var positiveInsights: [Insight] {
        return insights.filter { $0.impact == .positive }
    }

    /// Get improvement suggestions
    var improvementSuggestions: [Insight] {
        return insights.filter { $0.impact == .negative }
    }

    /// Icon for insight category
    func icon(for category: Insight.InsightCategory) -> String {
        switch category {
        case .timeOfDay:
            return "clock.fill"
        case .notifications:
            return "bell.fill"
        case .sessionPattern:
            return "chart.line.uptrend.xyaxis"
        case .weekdayVsWeekend:
            return "calendar"
        case .appSwitching:
            return "app.badge"
        }
    }

    /// Color for insight impact
    func color(for impact: Insight.InsightImpact) -> Color {
        switch impact {
        case .positive:
            return .green
        case .neutral:
            return .blue
        case .negative:
            return .orange
        }
    }
}
