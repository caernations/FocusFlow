import Foundation
import UIKit
import SwiftUI

class DataExporter {
    static let shared = DataExporter()

    private init() {}

    // MARK: - CSV Export

    func exportToCSV(sessions: [FocusSession]) -> URL? {
        guard !sessions.isEmpty else { return nil }

        var csvString = "Date,Start Time,End Time,Duration (min),Category,Focus Score,App Switches,Notifications,Screen Locks\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        for session in sessions {
            let date = dateFormatter.string(from: session.startTime)
            let startTime = timeFormatter.string(from: session.startTime)
            let endTime = timeFormatter.string(from: session.endTime)
            let duration = session.sessionDuration / 60
            let category = session.predictedCategory ?? "Unknown"
            let score = String(format: "%.2f", session.focusScore ?? 0.0)

            let row = "\(date),\(startTime),\(endTime),\(duration),\(category),\(score),\(session.appSwitchCount),\(session.notificationCount),\(session.screenLockCount)\n"
            csvString.append(row)
        }

        // Save to temporary directory
        let fileName = "FocusFlow_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }

    // MARK: - JSON Export

    func exportToJSON(sessions: [FocusSession]) -> URL? {
        guard !sessions.isEmpty else { return nil }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(sessions)

            let fileName = "FocusFlow_Export_\(Date().timeIntervalSince1970).json"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing JSON: \(error)")
            return nil
        }
    }

    // MARK: - PDF Report (Summary)

    func generatePDFReport(sessions: [FocusSession]) -> URL? {
        guard !sessions.isEmpty else { return nil }

        // Calculate statistics
        let totalSessions = sessions.count
        let totalMinutes = sessions.map { $0.sessionDuration }.reduce(0, +) / 60
        let avgScore = sessions.compactMap { $0.focusScore }.reduce(0.0, +) / Double(max(totalSessions, 1))

        let deepFocus = sessions.filter { $0.predictedCategory == "DeepFocus" }.count
        let shallowFocus = sessions.filter { $0.predictedCategory == "ShallowFocus" }.count
        let distracted = sessions.filter { $0.predictedCategory == "Distracted" }.count

        // Create PDF text
        let reportText = """
        FocusFlow - Focus Session Report
        Generated: \(Date())

        SUMMARY
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Total Sessions: \(totalSessions)
        Total Focus Time: \(totalMinutes) minutes
        Average Focus Score: \(Int(avgScore * 100))%

        BREAKDOWN BY CATEGORY
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Deep Focus: \(deepFocus) sessions (\(Int(Double(deepFocus)/Double(totalSessions)*100))%)
        Shallow Focus: \(shallowFocus) sessions (\(Int(Double(shallowFocus)/Double(totalSessions)*100))%)
        Distracted: \(distracted) sessions (\(Int(Double(distracted)/Double(totalSessions)*100))%)

        DETAILED SESSIONS
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """

        var fullReport = reportText

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        for (index, session) in sessions.enumerated() {
            let sessionInfo = """

            Session #\(index + 1)
            Date: \(dateFormatter.string(from: session.startTime))
            Duration: \(session.sessionDuration / 60) min
            Category: \(session.predictedCategory ?? "Unknown")
            Focus Score: \(Int((session.focusScore ?? 0) * 100))%
            Interruptions: \(session.appSwitchCount) switches, \(session.notificationCount) notifications

            """
            fullReport.append(sessionInfo)
        }

        // Convert to PDF
        let fileName = "FocusFlow_Report_\(Date().timeIntervalSince1970).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Create PDF from text
        let pdfData = createPDF(text: fullReport)

        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing PDF: \(error)")
            return nil
        }
    }

    // MARK: - Helper: Create PDF from Text

    private func createPDF(text: String) -> Data {
        let format = UIMarkupTextPrintFormatter(markupText: "<pre>\(text)</pre>")

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(format, startingAtPageAt: 0)

        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let printableRect = pageSize.insetBy(dx: 50, dy: 50)

        renderer.setValue(pageSize, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageSize, nil)

        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        return pdfData as Data
    }

    // MARK: - Statistics Summary

    func generateStatsSummary(sessions: [FocusSession]) -> String {
        guard !sessions.isEmpty else { return "No sessions recorded" }

        let totalSessions = sessions.count
        let totalMinutes = sessions.map { $0.sessionDuration }.reduce(0, +) / 60
        let avgScore = sessions.compactMap { $0.focusScore }.reduce(0.0, +) / Double(max(totalSessions, 1))

        return """
        FocusFlow Stats:
        • \(totalSessions) sessions
        • \(totalMinutes) minutes of focus
        • \(Int(avgScore * 100))% average score
        """
    }
}
