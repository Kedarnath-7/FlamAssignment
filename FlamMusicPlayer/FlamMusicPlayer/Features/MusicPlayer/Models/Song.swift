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
    
    init(
        id: String = String.generateID(),
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval,
        artworkURL: URL? = nil,
        audioURL: URL? = nil,
        source: MusicSource
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.audioURL = audioURL
        self.source = source
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
