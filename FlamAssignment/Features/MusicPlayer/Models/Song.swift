import Foundation

// MARK: - Song Model
/// Represents a music track from any source
struct Song: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artworkURL: URL?
    let audioURL: URL?
    let source: MusicSource
    let dominantColors: [String]?
    let energy: Float?
    let mood: MoodTag?
    let genre: String?
    
    init(
        id: String = String.generateID(),
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval,
        artworkURL: URL? = nil,
        audioURL: URL? = nil,
        source: MusicSource,
        dominantColors: [String]? = nil,
        energy: Float? = nil,
        mood: MoodTag? = nil,
        genre: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.audioURL = audioURL
        self.source = source
        self.dominantColors = dominantColors
        self.energy = energy
        self.mood = mood
        self.genre = genre
    }
}

// MARK: - Music Source
/// Enum representing different music sources
enum MusicSource: String, CaseIterable, Codable {
    case local = "Local Library"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    
    var iconName: String {
        switch self {
        case .local:
            return "music.note.house"
        case .spotify:
            return "music.note.tv"
        case .appleMusic:
            return "music.note"
        }
    }
}

// MARK: - Player State
/// Represents the current state of the music player
enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)
    
    var isPlaying: Bool {
        return self == .playing
    }
}

// MARK: - Playback Mode
/// Different playback modes for the player
enum PlaybackMode: CaseIterable {
    case normal
    case shuffle
    case repeatOne
    case repeatAll
    
    var iconName: String {
        switch self {
        case .normal:
            return "play"
        case .shuffle:
            return "shuffle"
        case .repeatOne:
            return "repeat.1"
        case .repeatAll:
            return "repeat"
        }
    }
}

// MARK: - Mood Tags
/// Represents different moods for music categorization
enum MoodTag: String, CaseIterable, Codable {
    case energetic = "Energetic"
    case chill = "Chill"
    case focus = "Focus"
    case party = "Party"
    case romantic = "Romantic"
    case melancholy = "Melancholy"
    case upbeat = "Upbeat"
    case relaxing = "Relaxing"
    
    var color: String {
        switch self {
        case .energetic: return "FF6B6B"
        case .chill: return "4ECDC4"
        case .focus: return "45B7D1"
        case .party: return "FFA726"
        case .romantic: return "EC407A"
        case .melancholy: return "8E24AA"
        case .upbeat: return "FFD54F"
        case .relaxing: return "81C784"
        }
    }
    
    var icon: String {
        switch self {
        case .energetic: return "bolt.fill"
        case .chill: return "leaf.fill"
        case .focus: return "brain.head.profile"
        case .party: return "party.popper.fill"
        case .romantic: return "heart.fill"
        case .melancholy: return "cloud.rain.fill"
        case .upbeat: return "sun.max.fill"
        case .relaxing: return "moon.stars.fill"
        }
    }
}
