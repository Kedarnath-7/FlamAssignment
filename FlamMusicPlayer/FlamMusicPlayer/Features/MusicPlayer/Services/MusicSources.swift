import Combine
import Foundation

// MARK: - MusicSourceProtocol (Strategy Pattern)
/// Protocol that defines how different music sources should behave
/// This is the Strategy Pattern - each source implements this differently
protocol MusicSourceProtocol {
    var sourceType: MusicSource { get }
    func fetchSongs() async throws -> [Song]
    func searchSongs(query: String) async throws -> [Song]
    func isAvailable() async -> Bool
}

// MARK: - Local Music Source
/// Handles local music files from device storage
class LocalMusicSource: MusicSourceProtocol {
    let sourceType: MusicSource = .local
    
    func fetchSongs() async throws -> [Song] {
        // Simulate fetching local songs
        // In a real app, you'd use MediaPlayer framework
        print("🎵 Fetching songs from Local Library...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Fetch from AudioDB API
        let apiSongs = try await NetworkService.shared.fetchSongsFromAudioDB(query: "rock")
        
        // Mix with some local songs
        let localSongs = [
            Song(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                duration: 355,
                source: .local
            ),
            Song(
                title: "Hotel California",
                artist: "Eagles",
                album: "Hotel California",
                duration: 391,
                source: .local
            ),
            Song(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                album: "Led Zeppelin IV",
                duration: 482,
                source: .local
            )
        ]
        
        return localSongs + apiSongs
    }
    
    func searchSongs(query: String) async throws -> [Song] {
        let allSongs = try await fetchSongs()
        return allSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
    func isAvailable() async -> Bool {
        // Local music is always available
        return true
    }
}

// MARK: - Spotify Music Source (Mock)
/// Mock implementation of Spotify integration
class SpotifyMusicSource: MusicSourceProtocol {
    let sourceType: MusicSource = .spotify
    
    func fetchSongs() async throws -> [Song] {
        print("🎵 Fetching songs from Spotify...")
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Fetch from Discogs API (mock)
        let apiSongs = try await NetworkService.shared.fetchSongsFromDiscogs(query: "pop")
        
        // Mix with some Spotify-style songs
        let spotifySongs = [
            Song(
                title: "Blinding Lights",
                artist: "The Weeknd",
                album: "After Hours",
                duration: 200,
                source: .spotify
            ),
            Song(
                title: "Watermelon Sugar",
                artist: "Harry Styles",
                album: "Fine Line",
                duration: 174,
                source: .spotify
            ),
            Song(
                title: "Levitating",
                artist: "Dua Lipa",
                album: "Future Nostalgia",
                duration: 203,
                source: .spotify
            )
        ]
        
        return spotifySongs + apiSongs
    }
    
    func searchSongs(query: String) async throws -> [Song] {
        let allSongs = try await fetchSongs()
        return allSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
    func isAvailable() async -> Bool {
        // Simulate checking Spotify connectivity
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return Bool.random() || true // Usually available for demo
    }
}

// MARK: - Apple Music Source (Mock)
/// Mock implementation of Apple Music integration
class AppleMusicSource: MusicSourceProtocol {
    let sourceType: MusicSource = .appleMusic
    
    func fetchSongs() async throws -> [Song] {
        print("🎵 Fetching songs from Apple Music...")
        
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        return [
            Song(
                title: "As It Was",
                artist: "Harry Styles",
                album: "Harry's House",
                duration: 167,
                source: .appleMusic
            ),
            Song(
                title: "Anti-Hero",
                artist: "Taylor Swift",
                album: "Midnights",
                duration: 200,
                source: .appleMusic
            ),
            Song(
                title: "Bad Habit",
                artist: "Steve Lacy",
                album: "Gemini Rights",
                duration: 221,
                source: .appleMusic
            )
        ]
    }
    
    func searchSongs(query: String) async throws -> [Song] {
        let allSongs = try await fetchSongs()
        return allSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
    func isAvailable() async -> Bool {
        // Simulate checking Apple Music subscription
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return true // Always available for demo
    }
}
