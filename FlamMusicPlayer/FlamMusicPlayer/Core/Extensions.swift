import Foundation

// MARK: - Common Extensions
/// Useful extensions that we'll use throughout the app

// MARK: - String Extensions
extension String {
    /// Generates a unique identifier string
    static func generateID() -> String {
        return UUID().uuidString
    }
    
    /// Truncates string to specified length
    func truncated(to length: Int) -> String {
        return count > length ? String(prefix(length)) + "..." : self
    }
}

// MARK: - Date Extensions
extension Date {
    /// Formats date for display in UI
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns formatted string for time duration
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Array Extensions
extension Array {
    /// Safe subscript that returns nil instead of crashing
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Error Types
/// Custom error types for better error handling
enum AppError: LocalizedError {
    case networkError(String)
    case audioError(String)
    case dataError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .audioError(let message):
            return "Audio Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
