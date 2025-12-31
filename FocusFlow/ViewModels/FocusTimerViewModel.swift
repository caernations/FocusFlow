import Foundation
import SwiftUI
import Combine

@MainActor
class FocusTimerViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var sessionDuration: TimeInterval = 25 * 60
    @Published var appSwitchCount = 0
    @Published var screenLockCount = 0
    @Published var notificationCount = 0
    @Published var currentSession: FocusSession?
    @Published var lastPrediction: (category: String, score: Double)?

    private var timer: Timer?
    private var sessionStartTime: Date?
    private let persistence = PersistenceManager.shared
    private let mlManager = MLManager.shared
    private let notifications = NotificationManager.shared
    private var liveActivityManager: Any?

    init() {
        if #available(iOS 16.1, *) {
            liveActivityManager = LiveActivityManager.shared
        }
    }

    func startSession() {
        isRunning = true
        sessionStartTime = Date()

        appSwitchCount = 0
        screenLockCount = 0
        notificationCount = 0

        notifications.scheduleTimerCompletion(in: timeRemaining)

        if #available(iOS 16.1, *), let manager = liveActivityManager as? LiveActivityManager {
            manager.startTimerActivity(
                duration: Int(timeRemaining),
                sessionType: "Focus Session"
            )
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }

        simulateBehavioralTracking()
    }

    func pauseSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil

        notifications.cancelTimerNotifications()

        if #available(iOS 16.1, *), let manager = liveActivityManager as? LiveActivityManager {
            manager.endTimerActivity()
        }
    }

    func endSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil

        // Cancel scheduled notifications
        notifications.cancelTimerNotifications()

        // Complete Live Activity (iOS 16.1+)
        if #available(iOS 16.1, *), let manager = liveActivityManager as? LiveActivityManager {
            manager.completeTimerActivity()
        }

        guard let startTime = sessionStartTime else { return }

        let endTime = Date()

        // Create session
        var session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            appSwitchCount: appSwitchCount,
            screenLockCount: screenLockCount,
            notificationCount: notificationCount
        )

        // Run ML inference
        if let prediction = mlManager.predict(for: session) {
            session.predictedCategory = prediction.category
            session.focusScore = prediction.score
            lastPrediction = prediction

            print("🎯 Session classified as: \(prediction.category)")
            print("📊 Focus score: \(String(format: "%.2f", prediction.score))")
        } else {
            // Fallback to rule-based
            session.predictedCategory = session.computeGroundTruthLabel()
            session.focusScore = session.computeFocusScore()
            lastPrediction = (session.predictedCategory!, session.focusScore!)
        }

        // Save to persistence
        persistence.saveFocusSession(session)
        currentSession = session

        // Reset timer
        resetTimer()
    }

    func resetTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timeRemaining = sessionDuration
        sessionStartTime = nil
        lastPrediction = nil
    }

    func updateSessionDuration(_ duration: TimeInterval) {
        sessionDuration = duration
        if !isRunning {
            timeRemaining = duration
        }
    }


    private func tick() {
        guard timeRemaining > 0 else {
            endSession()
            return
        }

        timeRemaining -= 1

        if #available(iOS 16.1, *), let manager = liveActivityManager as? LiveActivityManager {
            let elapsed = Int(sessionDuration - timeRemaining)
            manager.updateTimerActivity(elapsedSeconds: elapsed)
        }
    }

    private func simulateBehavioralTracking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 60...300), repeats: true) { [weak self] timer in
            guard let self = self, self.isRunning else {
                timer.invalidate()
                return
            }

            if Double.random(in: 0...1) < 0.3 {
                Task { @MainActor in
                    self.appSwitchCount += 1
                }
            }
        }

        Timer.scheduledTimer(withTimeInterval: Double.random(in: 120...600), repeats: true) { [weak self] timer in
            guard let self = self, self.isRunning else {
                timer.invalidate()
                return
            }

            if Double.random(in: 0...1) < 0.4 {
                Task { @MainActor in
                    self.notificationCount += 1
                }
            }
        }

        Timer.scheduledTimer(withTimeInterval: Double.random(in: 300...900), repeats: true) { [weak self] timer in
            guard let self = self, self.isRunning else {
                timer.invalidate()
                return
            }

            if Double.random(in: 0...1) < 0.2 {
                Task { @MainActor in
                    self.screenLockCount += 1
                }
            }
        }
    }


    var progress: Double {
        return 1.0 - (timeRemaining / sessionDuration)
    }

    var timeRemainingString: String {
        return timeRemaining.minuteSecondString
    }

    func incrementAppSwitches() {
        appSwitchCount += 1
    }

    func incrementNotifications() {
        notificationCount += 1
    }

    func incrementScreenLocks() {
        screenLockCount += 1
    }
}
