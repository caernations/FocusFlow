import ActivityKit
import WidgetKit
import SwiftUI

struct FocusTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var elapsedSeconds: Int
        var totalSeconds: Int
        var sessionType: String
    }

    var sessionDuration: Int
}

struct FocusFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
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
            .activityBackgroundTint(Color.black.opacity(0.8))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("FOCUS MODE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(1)

                            Text(context.state.sessionType)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(timeRemaining(endTime: context.state.endTime))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.cyan)

                            Text("\(context.state.elapsedSeconds / 60) / \(context.state.totalSeconds / 60) min")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 8)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * CGFloat(context.state.elapsedSeconds) / CGFloat(context.state.totalSeconds),
                                        height: 8
                                    )
                                    .shadow(color: Color.cyan.opacity(0.5), radius: 4)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.green)

                                Text("\(Int(Double(context.state.elapsedSeconds) / Double(context.state.totalSeconds) * 100))% Complete")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)

                                Text("Stay Focused!")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } compactTrailing: {
                Text(timeRemaining(endTime: context.state.endTime))
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12))
                    .foregroundStyle(.cyan)
            }
        }
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
