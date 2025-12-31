import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let fileURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("focus_sessions.json")
    }()

    private var sessions: [FocusSession] = []

    private init() {
        loadSessions()

        // Add dummy data if no sessions exist
        if sessions.isEmpty {
            generateDummyData()
        }
    }

    // MARK: - Dummy Data Generation

    private func generateDummyData() {
        let calendar = Calendar.current
        let now = Date()

        // Generate 30 sessions over the past 2 weeks
        for i in 0..<30 {
            let daysAgo = Int.random(in: 0...14)
            let hour = [9, 10, 11, 14, 15, 16, 19, 20].randomElement()!

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.day! -= daysAgo
            dateComponents.hour = hour
            dateComponents.minute = Int.random(in: 0...59)

            guard let startDate = calendar.date(from: dateComponents) else { continue }

            // Vary session types
            let sessionType: String
            let rand = Double.random(in: 0...1)
            if rand < 0.35 {
                sessionType = "DeepFocus"
            } else if rand < 0.80 {
                sessionType = "ShallowFocus"
            } else {
                sessionType = "Distracted"
            }

            // Generate realistic metrics based on type
            let duration: Int
            let appSwitches: Int
            let notifications: Int

            switch sessionType {
            case "DeepFocus":
                duration = Int.random(in: 1500...3000) // 25-50 min
                appSwitches = Int.random(in: 0...2)
                notifications = Int.random(in: 0...3)
            case "ShallowFocus":
                duration = Int.random(in: 600...1500) // 10-25 min
                appSwitches = Int.random(in: 2...5)
                notifications = Int.random(in: 2...6)
            default: // Distracted
                duration = Int.random(in: 180...600) // 3-10 min
                appSwitches = Int.random(in: 5...12)
                notifications = Int.random(in: 4...10)
            }

            let endDate = startDate.addingTimeInterval(TimeInterval(duration))
            let screenLocks = duration > 1200 ? Int.random(in: 0...2) : 0

            var session = FocusSession(
                startTime: startDate,
                endTime: endDate,
                appSwitchCount: appSwitches,
                screenLockCount: screenLocks,
                notificationCount: notifications
            )

            // Set predictions
            session.predictedCategory = session.computeGroundTruthLabel()
            session.focusScore = session.computeFocusScore()

            sessions.append(session)
        }

        saveToDisk()
        print("✅ Generated \(sessions.count) dummy sessions")
    }

    // MARK: - CRUD Operations

    func saveFocusSession(_ session: FocusSession) {
        sessions.append(session)
        saveToDisk()
    }

    func fetchAllSessions() -> [FocusSession] {
        return sessions.sorted { $0.startTime > $1.startTime }
    }

    func fetchSessions(from startDate: Date, to endDate: Date) -> [FocusSession] {
        return sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }.sorted { $0.startTime > $1.startTime }
    }

    func updateSessionWithPredictions(id: UUID, category: String, score: Double) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].predictedCategory = category
            sessions[index].focusScore = score
            saveToDisk()
        }
    }

    func deleteAllSessions() {
        sessions.removeAll()
        saveToDisk()
    }

    // MARK: - Disk Operations

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL)
        } catch {
            print("Error saving sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([FocusSession].self, from: data)
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
    }
}
