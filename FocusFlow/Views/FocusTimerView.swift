import SwiftUI

struct FocusTimerView: View {
    @StateObject private var viewModel = FocusTimerViewModel()
    @State private var showingSessionComplete = false

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.45),
                        Color(red: 0.2, green: 0.1, blue: 0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Progress ring
                        progressRing
                            .padding(.top, 20)

                        // Timer display
                        timerDisplay

                        // Session metrics
                        metricsSection

                        // Controls
                        controlButtons

                        // Last session result
                        if let prediction = viewModel.lastPrediction {
                            lastSessionCard(prediction: prediction)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Focus")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Progress Ring
    private var progressRing: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 25
                )
                .frame(width: 260, height: 260)
                .blur(radius: 20)

            // Background track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                .frame(width: 240, height: 240)

            // Progress
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.4, green: 0.8, blue: 1.0),
                            Color(red: 0.6, green: 0.4, blue: 1.0),
                            Color(red: 0.8, green: 0.2, blue: 1.0),
                            Color(red: 0.4, green: 0.8, blue: 1.0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                .shadow(color: Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.6), radius: 10)

            // Inner content
            VStack(spacing: 12) {
                Text(viewModel.timeRemainingString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(viewModel.isRunning ? "Focus Mode" : "Ready")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.timeRemainingString) remaining, \(Int(viewModel.progress * 100))% complete")
        .accessibilityValue(viewModel.isRunning ? "Timer running" : "Timer paused")
    }

    // MARK: - Timer Display
    private var timerDisplay: some View {
        HStack(spacing: 20) {
            statPill(value: "\(Int(viewModel.progress * 100))%", label: "Progress")
            statPill(value: "\(viewModel.sessionDuration / 60)m", label: "Duration")
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    title: "Switches",
                    value: "\(viewModel.appSwitchCount)",
                    icon: "arrow.left.arrow.right",
                    color: Color(red: 1.0, green: 0.6, blue: 0.3)
                )

                metricCard(
                    title: "Notifications",
                    value: "\(viewModel.notificationCount)",
                    icon: "bell.fill",
                    color: Color(red: 1.0, green: 0.3, blue: 0.5)
                )

                metricCard(
                    title: "Locks",
                    value: "\(viewModel.screenLockCount)",
                    icon: "lock.fill",
                    color: Color(red: 0.6, green: 0.5, blue: 1.0)
                )
            }
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if viewModel.isRunning {
                HStack(spacing: 12) {
                    Button(action: { viewModel.pauseSession() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 5)
                    }

                    Button(action: { viewModel.endSession() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                    }
                }
            } else {
                Button(action: { viewModel.startSession() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("Start Focus Session")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.8, blue: 1.0),
                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.5, green: 0.6, blue: 1.0).opacity(0.5), radius: 15, y: 8)
                }
                .accessibilityLabel("Start Focus Session")
                .accessibilityHint("Begins a \(viewModel.sessionDuration / 60) minute focus timer")

                if viewModel.timeRemaining != viewModel.sessionDuration {
                    Button(action: { viewModel.resetTimer() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    // MARK: - Last Session Card
    private func lastSessionCard(prediction: (category: String, score: Double)) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(red: 0.4, green: 1.0, blue: 0.6))
                    .font(.system(size: 24))
                Text("Session Complete!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(prediction.category)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.categoryColor(for: prediction.category))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(Color.white.opacity(0.2))

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(prediction.score.percentageString)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.scoreGradient(for: prediction.score))
                        .frame(width: geometry.size.width * prediction.score, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    FocusTimerView()
}
