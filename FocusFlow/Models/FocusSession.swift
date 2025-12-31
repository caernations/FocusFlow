import Foundation

/// Represents a single focus session with behavioral metrics
struct FocusSession: Identifiable, Codable {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var sessionDuration: Int // seconds
    var appSwitchCount: Int
    var screenLockCount: Int
    var notificationCount: Int
    var startHour: Int // 0-23
    var dayOfWeek: Int // 0-6 (0 = Sunday)

    // ML Predictions (populated after inference)
    var predictedCategory: String? // DeepFocus, ShallowFocus, Distracted
    var focusScore: Double? // 0.0 - 1.0

    init(id: UUID = UUID(),
         startTime: Date,
         endTime: Date,
         appSwitchCount: Int,
         screenLockCount: Int,
         notificationCount: Int) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sessionDuration = Int(endTime.timeIntervalSince(startTime))
        self.appSwitchCount = appSwitchCount
        self.screenLockCount = screenLockCount
        self.notificationCount = notificationCount

        let calendar = Calendar.current
        self.startHour = calendar.component(.hour, from: startTime)
        self.dayOfWeek = calendar.component(.weekday, from: startTime) - 1 // Convert to 0-6

        self.predictedCategory = nil
        self.focusScore = nil
    }

    /// Compute ground truth label using heuristics (for training data generation)
    func computeGroundTruthLabel() -> String {
        if sessionDuration > 1500 && appSwitchCount < 2 {
            return "DeepFocus"
        } else if sessionDuration >= 600 && sessionDuration <= 1500 {
            return "ShallowFocus"
        } else if sessionDuration < 600 || appSwitchCount > 5 {
            return "Distracted"
        } else {
            return "ShallowFocus"
        }
    }

    /// Compute focus score (0.0 - 1.0) using normalized features
    func computeFocusScore() -> Double {
        // Normalize duration (max 3600s = 1 hour)
        let durationScore = min(Double(sessionDuration) / 3600.0, 1.0)

        // Penalty for app switches (exponential decay)
        let appSwitchPenalty = exp(-Double(appSwitchCount) * 0.3)

        // Penalty for notifications (linear penalty)
        let notificationPenalty = max(0.0, 1.0 - Double(notificationCount) * 0.1)

        // Penalty for screen locks
        let screenLockPenalty = max(0.0, 1.0 - Double(screenLockCount) * 0.15)

        // Weighted combination
        let score = durationScore * 0.4 + appSwitchPenalty * 0.3 +
                    notificationPenalty * 0.2 + screenLockPenalty * 0.1

        return min(max(score, 0.0), 1.0)
    }
}
