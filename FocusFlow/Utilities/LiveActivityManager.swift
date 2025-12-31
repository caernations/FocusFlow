import Foundation
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<FocusTimerAttributes>?

    private init() {}

    // MARK: - Start Live Activity

    func startTimerActivity(duration: Int, sessionType: String = "Focus Session") {
        // End any existing activity first
        endTimerActivity()

        let attributes = FocusTimerAttributes(sessionDuration: duration)
        let contentState = FocusTimerAttributes.ContentState(
            endTime: Date().addingTimeInterval(TimeInterval(duration)),
            elapsedSeconds: 0,
            totalSeconds: duration,
            sessionType: sessionType
        )

        do {
            let activity = try Activity<FocusTimerAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )

            currentActivity = activity
            print("✅ Live Activity started: \(activity.id)")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
        }
    }

    // MARK: - Update Live Activity

    func updateTimerActivity(elapsedSeconds: Int) {
        guard let activity = currentActivity else { return }

        Task {
            let updatedState = FocusTimerAttributes.ContentState(
                endTime: activity.contentState.endTime,
                elapsedSeconds: elapsedSeconds,
                totalSeconds: activity.contentState.totalSeconds,
                sessionType: activity.contentState.sessionType
            )

            await activity.update(using: updatedState)
        }
    }

    // MARK: - End Live Activity

    func endTimerActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity ended")
        }
    }

    // MARK: - Complete Live Activity (show completion state)

    func completeTimerActivity() {
        guard let activity = currentActivity else { return }

        Task {
            // Update to final state
            let finalState = FocusTimerAttributes.ContentState(
                endTime: Date(),
                elapsedSeconds: activity.contentState.totalSeconds,
                totalSeconds: activity.contentState.totalSeconds,
                sessionType: activity.contentState.sessionType
            )

            await activity.update(using: finalState)

            // Dismiss after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity completed and dismissed")
        }
    }
}
