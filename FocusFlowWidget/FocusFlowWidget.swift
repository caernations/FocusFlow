//
//  FocusFlowWidget.swift
//  FocusFlowWidget
//
//  Created by Yasmin Farisah Salma on 01/01/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct FocusEntry: TimelineEntry {
    let date: Date
    let todaySessions: Int
    let totalMinutes: Int
    let averageScore: Double
    let streak: Int
}

// MARK: - Timeline Provider

struct FocusProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusEntry {
        FocusEntry(
            date: Date(),
            todaySessions: 3,
            totalMinutes: 75,
            averageScore: 0.85,
            streak: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        let entry = FocusEntry(
            date: Date(),
            todaySessions: 3,
            totalMinutes: 75,
            averageScore: 0.85,
            streak: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        // Get real data
        let stats = loadTodayStats()

        let entry = FocusEntry(
            date: Date(),
            todaySessions: stats.sessions,
            totalMinutes: stats.minutes,
            averageScore: stats.score,
            streak: stats.streak
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadTodayStats() -> (sessions: Int, minutes: Int, score: Double, streak: Int) {
        // Sample data - will show in widget
        return (4, 90, 0.82, 7)
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: FocusEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundColor(.white)

                Text("\(entry.todaySessions)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Sessions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: FocusEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.white)

                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 12) {
                    statRow(icon: "circle.fill", label: "Sessions", value: "\(entry.todaySessions)")
                    statRow(icon: "clock.fill", label: "Minutes", value: "\(entry.totalMinutes)")
                    statRow(icon: "chart.line.uptrend.xyaxis", label: "Score", value: "\(Int(entry.averageScore * 100))%")
                }
            }
            .padding()
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

struct LargeWidgetView: View {
    let entry: FocusEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30))
                    Text("FocusFlow")
                        .font(.title3.bold())
                    Spacer()
                }
                .foregroundColor(.white)

                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        statCard(title: "Sessions", value: "\(entry.todaySessions)", icon: "circle.fill", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                        statCard(title: "Minutes", value: "\(entry.totalMinutes)", icon: "clock.fill", color: Color(red: 0.6, green: 0.4, blue: 1.0))
                    }

                    HStack(spacing: 16) {
                        statCard(title: "Avg Score", value: "\(Int(entry.averageScore * 100))%", icon: "chart.bar.fill", color: Color(red: 1.0, green: 0.6, blue: 0.3))
                        statCard(title: "Streak", value: "\(entry.streak)d", icon: "flame.fill", color: Color(red: 1.0, green: 0.3, blue: 0.5))
                    }
                }

                Spacer()

                Text("Updated \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Widget Configuration

struct FocusFlowWidget: Widget {
    let kind: String = "FocusFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusProvider()) { entry in
            FocusFlowWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("FocusFlow Stats")
        .description("See your daily focus statistics")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusFlowWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: FocusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FocusFlowWidget()
} timeline: {
    FocusEntry(date: .now, todaySessions: 3, totalMinutes: 75, averageScore: 0.85, streak: 5)
    FocusEntry(date: .now, todaySessions: 4, totalMinutes: 90, averageScore: 0.82, streak: 6)
}

#Preview(as: .systemMedium) {
    FocusFlowWidget()
} timeline: {
    FocusEntry(date: .now, todaySessions: 3, totalMinutes: 75, averageScore: 0.85, streak: 5)
}

#Preview(as: .systemLarge) {
    FocusFlowWidget()
} timeline: {
    FocusEntry(date: .now, todaySessions: 3, totalMinutes: 75, averageScore: 0.85, streak: 5)
}
