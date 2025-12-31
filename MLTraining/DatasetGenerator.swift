#!/usr/bin/env swift
//
//  DatasetGenerator.swift
//  FocusFlow ML Training
//
//  Generates synthetic focus session dataset with realistic distributions
//  Run: swift DatasetGenerator.swift
//

import Foundation

// MARK: - FocusSession Model (duplicated for standalone script)
struct FocusSessionData {
    let sessionDuration: Int // seconds
    let appSwitchCount: Int
    let screenLockCount: Int
    let startHour: Int // 0-23
    let dayOfWeek: Int // 0-6
    let notificationCount: Int

    // Computed values
    var label: String {
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

    var focusScore: Double {
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

// MARK: - Dataset Generator
class DatasetGenerator {
    let numberOfSamples: Int

    init(numberOfSamples: Int = 500) {
        self.numberOfSamples = numberOfSamples
    }

    /// Generate realistic session duration based on session type
    func generateDuration(for type: String) -> Int {
        switch type {
        case "DeepFocus":
            // Deep focus: 25-60 minutes (1500-3600s)
            return Int.random(in: 1500...3600)
        case "ShallowFocus":
            // Shallow focus: 10-25 minutes (600-1500s)
            return Int.random(in: 600...1500)
        case "Distracted":
            // Distracted: 1-10 minutes (60-600s)
            return Int.random(in: 60...600)
        default:
            return 600
        }
    }

    /// Generate app switch count based on session type
    func generateAppSwitches(for type: String) -> Int {
        switch type {
        case "DeepFocus":
            // Deep focus: minimal switches (0-2)
            return Int.random(in: 0...2)
        case "ShallowFocus":
            // Shallow focus: moderate switches (2-5)
            return Int.random(in: 2...5)
        case "Distracted":
            // Distracted: many switches (5-15)
            return Int.random(in: 5...15)
        default:
            return 3
        }
    }

    /// Generate notification count with realistic distribution
    func generateNotifications() -> Int {
        // Most sessions have 0-5 notifications, some have more
        let rand = Double.random(in: 0...1)
        if rand < 0.6 {
            return Int.random(in: 0...2) // 60% have few notifications
        } else if rand < 0.9 {
            return Int.random(in: 3...7) // 30% have moderate
        } else {
            return Int.random(in: 8...15) // 10% have many
        }
    }

    /// Generate screen lock count based on duration
    func generateScreenLocks(duration: Int) -> Int {
        // Longer sessions might have more locks, but not necessarily
        let expectedLocks = duration / 1200 // roughly 1 lock per 20 minutes
        let variance = Int.random(in: -1...2)
        return max(0, expectedLocks + variance)
    }

    /// Generate start hour with realistic distribution
    func generateStartHour() -> Int {
        // Peak productivity hours: 9-11 AM and 2-4 PM
        let rand = Double.random(in: 0...1)
        if rand < 0.4 {
            // 40% morning focus (9-11 AM)
            return Int.random(in: 9...11)
        } else if rand < 0.7 {
            // 30% afternoon focus (14-16 / 2-4 PM)
            return Int.random(in: 14...16)
        } else if rand < 0.85 {
            // 15% early morning (6-9 AM)
            return Int.random(in: 6...9)
        } else {
            // 15% evening (17-22 / 5-10 PM)
            return Int.random(in: 17...22)
        }
    }

    /// Generate day of week (weekdays have more sessions)
    func generateDayOfWeek() -> Int {
        let rand = Double.random(in: 0...1)
        if rand < 0.8 {
            // 80% weekdays (Monday=1 to Friday=5)
            return Int.random(in: 1...5)
        } else {
            // 20% weekends (Saturday=6, Sunday=0)
            return [0, 6].randomElement()!
        }
    }

    /// Generate a single session
    func generateSession(preferredType: String? = nil) -> FocusSessionData {
        // Determine session type
        let type: String
        if let preferred = preferredType {
            type = preferred
        } else {
            // Realistic distribution: 30% deep, 50% shallow, 20% distracted
            let rand = Double.random(in: 0...1)
            if rand < 0.3 {
                type = "DeepFocus"
            } else if rand < 0.8 {
                type = "ShallowFocus"
            } else {
                type = "Distracted"
            }
        }

        // Generate features based on type
        let duration = generateDuration(for: type)
        let appSwitches = generateAppSwitches(for: type)
        let screenLocks = generateScreenLocks(duration: duration)
        let notifications = generateNotifications()
        let startHour = generateStartHour()
        let dayOfWeek = generateDayOfWeek()

        return FocusSessionData(
            sessionDuration: duration,
            appSwitchCount: appSwitches,
            screenLockCount: screenLocks,
            startHour: startHour,
            dayOfWeek: dayOfWeek,
            notificationCount: notifications
        )
    }

    /// Generate complete dataset
    func generateDataset() -> [FocusSessionData] {
        var dataset: [FocusSessionData] = []

        // Ensure balanced distribution
        let deepFocusCount = Int(Double(numberOfSamples) * 0.3)
        let shallowFocusCount = Int(Double(numberOfSamples) * 0.5)
        let distractedCount = numberOfSamples - deepFocusCount - shallowFocusCount

        // Generate deep focus sessions
        for _ in 0..<deepFocusCount {
            dataset.append(generateSession(preferredType: "DeepFocus"))
        }

        // Generate shallow focus sessions
        for _ in 0..<shallowFocusCount {
            dataset.append(generateSession(preferredType: "ShallowFocus"))
        }

        // Generate distracted sessions
        for _ in 0..<distractedCount {
            dataset.append(generateSession(preferredType: "Distracted"))
        }

        // Shuffle to mix session types
        return dataset.shuffled()
    }

    /// Export dataset to CSV
    func exportToCSV(dataset: [FocusSessionData], filename: String = "GeneratedDataset.csv") {
        var csv = "session_duration,app_switch_count,screen_lock_count,start_hour,day_of_week,notification_count,label,focus_score\n"

        for session in dataset {
            csv += "\(session.sessionDuration),"
            csv += "\(session.appSwitchCount),"
            csv += "\(session.screenLockCount),"
            csv += "\(session.startHour),"
            csv += "\(session.dayOfWeek),"
            csv += "\(session.notificationCount),"
            csv += "\(session.label),"
            csv += String(format: "%.4f", session.focusScore)
            csv += "\n"
        }

        // Write to file
        let fileURL = URL(fileURLWithPath: filename)
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Dataset generated successfully: \(filename)")
            print("   Total samples: \(dataset.count)")

            // Print distribution
            let deepCount = dataset.filter { $0.label == "DeepFocus" }.count
            let shallowCount = dataset.filter { $0.label == "ShallowFocus" }.count
            let distractedCount = dataset.filter { $0.label == "Distracted" }.count

            print("   DeepFocus: \(deepCount)")
            print("   ShallowFocus: \(shallowCount)")
            print("   Distracted: \(distractedCount)")
        } catch {
            print("❌ Error writing CSV: \(error)")
        }
    }
}

// MARK: - Main Execution
print("🚀 FocusFlow Dataset Generator")
print("==============================\n")

let generator = DatasetGenerator(numberOfSamples: 500)
let dataset = generator.generateDataset()

// Get the script directory
let currentPath = FileManager.default.currentDirectoryPath
let csvPath = (currentPath as NSString).appendingPathComponent("GeneratedDataset.csv")

generator.exportToCSV(dataset: dataset, filename: csvPath)

print("\n📊 Sample data preview:")
print("First 5 rows:")
for (index, session) in dataset.prefix(5).enumerated() {
    print("  [\(index + 1)] Duration: \(session.sessionDuration)s, " +
          "Switches: \(session.appSwitchCount), " +
          "Label: \(session.label), " +
          "Score: \(String(format: "%.2f", session.focusScore))")
}

print("\n✨ Done! Ready for Create ML training.")
