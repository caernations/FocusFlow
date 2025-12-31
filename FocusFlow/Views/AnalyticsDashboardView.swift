import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.totalSessions == 0 {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Time range picker
                            timeRangePicker

                            // Summary cards
                            summaryCards

                            // Category distribution
                            categoryDistributionSection

                            // Daily focus scores chart
                            dailyFocusChart

                            // Hourly distribution
                            hourlyDistributionChart

                            // Top sessions
                            topSessionsSection

                            Spacer(minLength: 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
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

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("No Data Yet")
                    .font(.title.bold())

                Text("Complete your first focus session to see analytics")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("Go to Focus tab")
                        .font(.subheadline)
                }

                HStack(spacing: 8) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("Start a focus session")
                        .font(.subheadline)
                }

                HStack(spacing: 8) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("Complete it to see insights")
                        .font(.subheadline)
                }
            }
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            ForEach(AnalyticsViewModel.TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedTimeRange) { _ in
            viewModel.loadSessions()
        }
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 16) {
            summaryCard(
                title: "Total Sessions",
                value: "\(viewModel.totalSessions)",
                icon: "chart.bar.fill",
                color: .blue
            )

            summaryCard(
                title: "Avg Score",
                value: viewModel.averageFocusScore.percentageString,
                icon: "target",
                color: .green
            )

            summaryCard(
                title: "Focus Time",
                value: viewModel.totalFocusTime.durationString,
                icon: "clock.fill",
                color: .purple
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Category Distribution
    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Quality Distribution")
                .font(.headline)

            ForEach(viewModel.getCategoryPercentages(), id: \.category) { item in
                categoryBar(category: item.category, percentage: item.percentage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    private func categoryBar(category: String, percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category)
                    .font(.subheadline)
                Spacer()
                Text(percentage.percentageString)
                    .font(.subheadline.bold())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.categoryColor(for: category))
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Daily Focus Chart
    private var dailyFocusChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Focus Trends")
                .font(.headline)

            let data = viewModel.getDailyFocusScores()

            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(data, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(Int(val * 100))%")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Hourly Distribution Chart
    private var hourlyDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions by Hour")
                .font(.headline)

            let data = viewModel.getHourlyDistribution().filter { $0.count > 0 }

            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(data, id: \.hour) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour):00")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Top Sessions
    private var topSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performing Sessions")
                .font(.headline)

            let topSessions = viewModel.getTopSessions()

            if topSessions.isEmpty {
                Text("No sessions yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(topSessions) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct SessionRowView: View {
    let session: FocusSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime.dateString)
                    .font(.subheadline.bold())

                Text("\(session.sessionDuration / 60) min • \(session.startTime.timeString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let category = session.predictedCategory {
                    Text(category)
                        .font(.caption.bold())
                        .foregroundColor(Color.categoryColor(for: category))
                }

                if let score = session.focusScore {
                    Text(score.percentageString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AnalyticsDashboardView()
}
