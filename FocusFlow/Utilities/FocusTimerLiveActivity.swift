import Foundation
import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Activity Attributes

@available(iOS 16.1, *)
struct FocusTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var elapsedSeconds: Int
        var totalSeconds: Int
        var sessionType: String
    }

    var sessionDuration: Int // Total duration in seconds
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            // Lock screen UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Focus Session")
                            .font(.caption)
                        Text(context.state.sessionType)
                            .font(.caption2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeRemaining(endTime: context.state.endTime))
                        .font(.title3)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(Int(Double(context.state.elapsedSeconds) / Double(context.state.totalSeconds) * 100))% complete")
                        .font(.caption)
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "timer")
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island)
                Text(timeRemaining(endTime: context.state.endTime))
                    .monospacedDigit()
            } minimal: {
                // Minimal view (when multiple activities)
                Image(systemName: "timer")
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<FocusTimerAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("FocusFlow")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(context.state.sessionType)
                        .font(.subheadline.bold())
                }

                Spacer()

                Text(timeRemaining(endTime: context.state.endTime))
                    .font(.title3.bold())
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(context.state.elapsedSeconds) / CGFloat(context.state.totalSeconds),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(Double(context.state.elapsedSeconds) / Double(context.state.totalSeconds) * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(context.state.elapsedSeconds / 60) / \(context.state.totalSeconds / 60) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Helper Views

    private func progressBar(elapsed: Int, total: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.cyan)
                    .frame(
                        width: geometry.size.width * CGFloat(elapsed) / CGFloat(total),
                        height: 4
                    )
            }
        }
        .frame(height: 4)
    }

    private func timeRemaining(endTime: Date) -> String {
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            return "0:00"
        }

        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
