import SwiftUI

// MARK: - Smart Suggestion Card
/// Compact card showing smart queue suggestions
struct SmartSuggestionCard: View {
    let song: Song
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork with mood indicator
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dynamicBackground(for: song))
                    .frame(width: 120, height: 80)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: song.source.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            if let mood = song.mood {
                                Image(systemName: mood.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    )
                
                // Energy indicator
                if let energy = song.energy {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(Int(energy * 100))")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.primary)
                        )
                        .offset(x: -4, y: 4)
                }
            }
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(song.artist)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Mood tag
                if let mood = song.mood {
                    Text(mood.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: mood.color).opacity(0.2))
                        )
                        .foregroundColor(Color(hex: mood.color))
                }
            }
        }
        .frame(width: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Smart Suggestions Sheet
/// Full screen view for smart suggestions
struct SmartSuggestionsView: View {
    let suggestions: [Song]
    let onSongSelected: (Song) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(suggestions) { song in
                        EnhancedSongRow(
                            song: song,
                            onTap: {
                                onSongSelected(song)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Song Row
/// Enhanced song row with mood and energy indicators
struct EnhancedSongRow: View {
    let song: Song
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Enhanced artwork
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dynamicBackground(for: song))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: song.source.iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
                
                // Mood indicator
                if let mood = song.mood {
                    HStack(spacing: 2) {
                        Image(systemName: mood.icon)
                            .font(.system(size: 8, weight: .bold))
                        Text(mood.rawValue.prefix(3))
                            .font(.system(size: 6, weight: .bold))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                    .offset(x: 4, y: -4)
                }
            }
            
            // Song info with energy bar
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(song.artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let genre = song.genre {
                        Text("• \(genre)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                // Energy bar
                if let energy = song.energy {
                    HStack(spacing: 4) {
                        Text("Energy")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.dynamicAccent(for: song))
                                    .frame(width: geometry.size.width * CGFloat(energy), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("\(Int(energy * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Duration and similarity score
            VStack(alignment: .trailing, spacing: 4) {
                Text(Date.formatDuration(song.duration))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                // Similarity score (mock)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("95%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Queue Context Extension
extension QueueContext {
    var displayName: String {
        switch self {
        case .general: return "General"
        case .workout: return "Workout"
        case .focus: return "Focus"
        case .party: return "Party"
        case .relaxing: return "Relaxing"
        }
    }
}
