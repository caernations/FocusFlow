import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Positive insights
                        if !viewModel.positiveInsights.isEmpty {
                            insightSection(
                                title: "What's Working Well",
                                insights: viewModel.positiveInsights,
                                color: .green
                            )
                        }

                        // Improvement suggestions
                        if !viewModel.improvementSuggestions.isEmpty {
                            insightSection(
                                title: "Areas for Improvement",
                                insights: viewModel.improvementSuggestions,
                                color: .orange
                            )
                        }

                        // All insights
                        if viewModel.insights.isEmpty {
                            emptyState
                        } else {
                            allInsightsSection
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("AI-Powered Insights")
                .font(.title2.bold())

            Text("Personalized recommendations based on your focus patterns")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }

    // MARK: - Insight Section
    private func insightSection(title: String, insights: [Insight], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            ForEach(insights) { insight in
                InsightCard(insight: insight, viewModel: viewModel)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - All Insights Section
    private var allInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Insights (\(viewModel.insights.count))")
                .font(.headline)

            ForEach(viewModel.insights) { insight in
                InsightCard(insight: insight, viewModel: viewModel)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Not Enough Data Yet")
                .font(.title3.bold())

            Text("Complete more focus sessions to receive personalized insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let insight: Insight
    let viewModel: InsightsViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: viewModel.icon(for: insight.category))
                .font(.title2)
                .foregroundColor(viewModel.color(for: insight.impact))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(viewModel.color(for: insight.impact).opacity(0.2))
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.subheadline.bold())

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    InsightsView()
}
