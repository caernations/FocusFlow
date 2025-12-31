import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Format as time string (e.g., "2:30 PM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Format as date string (e.g., "Jan 1, 2024")
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    /// Start of week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    /// Format as MM:SS
    var minuteSecondString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format as human-readable duration
    var durationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let focusGreen = Color.green
    static let focusBlue = Color.blue
    static let focusOrange = Color.orange
    static let focusRed = Color.red

    /// Color for focus category
    static func categoryColor(for category: String) -> Color {
        switch category {
        case "DeepFocus":
            return .green
        case "ShallowFocus":
            return .orange
        case "Distracted":
            return .red
        default:
            return .gray
        }
    }

    /// Gradient for focus score
    static func scoreGradient(for score: Double) -> LinearGradient {
        let startColor: Color = score > 0.7 ? .green : (score > 0.4 ? .orange : .red)
        let endColor: Color = score > 0.7 ? .blue : (score > 0.4 ? .yellow : .orange)

        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Double Extensions
extension Double {
    /// Format as percentage
    var percentageString: String {
        return String(format: "%.0f%%", self * 100)
    }

    /// Format with 2 decimal places
    var twoDecimalString: String {
        return String(format: "%.2f", self)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply card styling
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
