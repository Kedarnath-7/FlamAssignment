import Foundation
import SwiftUI

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

// MARK: - Color Extensions
extension Color {
    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Generate dynamic colors from song data
    static func dynamicBackground(for song: Song?) -> LinearGradient {
        guard let song = song else {
            return LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        if let colors = song.dominantColors, colors.count >= 2 {
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: colors[0]), Color(hex: colors[1])]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Fallback to mood-based colors
        if let mood = song.mood {
            let baseColor = Color(hex: mood.color)
            return LinearGradient(
                gradient: Gradient(colors: [baseColor, baseColor.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Fallback to source-based colors
        let sourceColor = song.source == .local ? Color.blue : 
                         song.source == .spotify ? Color.green : Color.pink
        return LinearGradient(
            gradient: Gradient(colors: [sourceColor, sourceColor.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Get accent color for current song
    static func dynamicAccent(for song: Song?) -> Color {
        guard let song = song else { return .accentColor }
        
        if let colors = song.dominantColors, !colors.isEmpty {
            return Color(hex: colors[0])
        }
        
        if let mood = song.mood {
            return Color(hex: mood.color)
        }
        
        return song.source == .local ? .blue : 
               song.source == .spotify ? .green : .pink
    }
    
    /// Get search bar background color for better visibility
    static func searchBarBackground(for song: Song?) -> Color {
        if let song = song {
            if let colors = song.dominantColors, !colors.isEmpty {
                return Color(hex: colors[0]).opacity(0.1)
            }
            
            if let mood = song.mood {
                return Color(hex: mood.color).opacity(0.1)
            }
        }
        
        return Color(.systemGray6).opacity(0.3)
    }
    
    /// Get contrasting text color for search bar
    static func searchBarText(for song: Song?) -> Color {
        return Color.white.opacity(0.9)
    }
}

