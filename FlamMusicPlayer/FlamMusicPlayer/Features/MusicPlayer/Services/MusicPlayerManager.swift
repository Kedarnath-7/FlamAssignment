import AVFoundation
import UIKit
import Combine
import Foundation

// MARK: - AudioPlayerProtocol
/// Protocol for audio playback functionality
/// Allows for easy testing with mock implementations
protocol AudioPlayerProtocol {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }
    
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval)
    func setVolume(_ volume: Float)
}

// MARK: - MusicPlayerManager (Singleton Pattern)
/// Singleton class that manages music playback across the entire app
/// Uses Observer Pattern with Combine for state notifications
class MusicPlayerManager: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = MusicPlayerManager()
    
    // MARK: - Published Properties (Observer Pattern)
    @Published var currentSong: Song?
    @Published var playerState: PlayerState = .idle
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackMode: PlaybackMode = .normal
    @Published var volume: Float = 0.7
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Music Sources (Strategy Pattern)
    private let musicSources: [MusicSourceProtocol] = [
        LocalMusicSource(),
        SpotifyMusicSource(),
        AppleMusicSource()
    ]
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
        setupObservers()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // Configure audio session for music playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("🔊 Audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            playerState = .error("Failed to setup audio session")
        }
    }
    
    // MARK: - Observer Setup
    private func setupObservers() {
        // Listen for app going to background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        // Listen for app coming to foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public Methods
extension MusicPlayerManager {
    
    /// Load and play a song
    func play(song: Song) {
        currentSong = song
        playerState = .loading
        
        // In a real app, you'd load the actual audio file
        // For demo purposes, we'll simulate playback
        simulateAudioPlayback(for: song)
    }
    
    /// Play current song or resume playback
    func play() {
        guard let song = currentSong else {
            print("⚠️ No song selected")
            return
        }
        
        if audioPlayer?.isPlaying == true {
            return // Already playing
        }
        
        audioPlayer?.play()
        playerState = .playing
        startProgressTimer()
        print("▶️ Playing: \(song.title)")
    }
    
    /// Pause current playback
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopProgressTimer()
        print("⏸️ Playback paused")
    }
    
    /// Stop playback and reset
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playerState = .stopped
        currentTime = 0
        stopProgressTimer()
        print("⏹️ Playback stopped")
    }
    
    /// Seek to specific time in current song
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let seekTime = min(max(time, 0), duration)
        player.currentTime = seekTime
        currentTime = seekTime
        print("⏪ Seeked to: \(Date.formatDuration(seekTime))")
    }
    
    /// Play next song in queue
    func playNext() {
        guard !queue.isEmpty else { return }
        
        let nextIndex: Int
        switch playbackMode {
        case .normal, .repeatAll:
            nextIndex = (currentIndex + 1) % queue.count
        case .shuffle:
            nextIndex = Int.random(in: 0..<queue.count)
        case .repeatOne:
            nextIndex = currentIndex
        }
        
        currentIndex = nextIndex
        play(song: queue[nextIndex])
    }
    
    /// Play previous song in queue
    func playPrevious() {
        guard !queue.isEmpty else { return }
        
        let previousIndex = currentIndex > 0 ? currentIndex - 1 : queue.count - 1
        currentIndex = previousIndex
        play(song: queue[previousIndex])
    }
    
    /// Set playback queue
    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        queue = songs
        currentIndex = startIndex
        if !songs.isEmpty {
            play(song: songs[startIndex])
        }
    }
    
    /// Toggle playback mode
    func togglePlaybackMode() {
        let modes = PlaybackMode.allCases
        let currentModeIndex = modes.firstIndex(of: playbackMode) ?? 0
        let nextIndex = (currentModeIndex + 1) % modes.count
        playbackMode = modes[nextIndex]
        print("🔀 Playback mode: \(playbackMode)")
    }
    
    /// Set volume (0.0 to 1.0)
    func setVolume(_ newVolume: Float) {
        let clampedVolume = min(max(newVolume, 0.0), 1.0)
        volume = clampedVolume
        audioPlayer?.volume = clampedVolume
    }
    
    // MARK: - Queue Management
    /// Add song to the end of queue
    func addToQueue(_ song: Song) {
        queue.append(song)
        print("➕ Added '\(song.title)' to queue")
    }
    
    /// Add songs to the end of queue
    func addToQueue(_ songs: [Song]) {
        queue.append(contentsOf: songs)
        print("➕ Added \(songs.count) songs to queue")
    }
    
    /// Insert song at specific position in queue
    func insertInQueue(_ song: Song, at index: Int) {
        let insertIndex = min(max(index, 0), queue.count)
        queue.insert(song, at: insertIndex)
        
        // Adjust current index if needed
        if insertIndex <= currentIndex {
            currentIndex += 1
        }
        print("➕ Inserted '\(song.title)' at position \(insertIndex)")
    }
    
    /// Remove song from queue at specific index
    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        
        let removedSong = queue.remove(at: index)
        
        // Adjust current index if needed
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            // If we removed current song, stop playback
            if queue.isEmpty {
                stop()
                currentIndex = 0
            } else {
                // Play next song in queue, or previous if we were at the end
                currentIndex = min(currentIndex, queue.count - 1)
                if !queue.isEmpty {
                    play(song: queue[currentIndex])
                }
            }
        }
        print("➖ Removed '\(removedSong.title)' from queue")
    }
    
    /// Remove specific song from queue
    func removeFromQueue(_ song: Song) {
        if let index = queue.firstIndex(where: { $0.id == song.id }) {
            removeFromQueue(at: index)
        }
    }
    
    /// Reorder song in queue (move from old index to new index)
    func reorderInQueue(from sourceIndex: Int, to destinationIndex: Int) {
        guard queue.indices.contains(sourceIndex),
              queue.indices.contains(destinationIndex),
              sourceIndex != destinationIndex else { return }
        
        let song = queue.remove(at: sourceIndex)
        queue.insert(song, at: destinationIndex)
        
        // Adjust current index if needed
        if sourceIndex == currentIndex {
            currentIndex = destinationIndex
        } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
            currentIndex -= 1
        } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
            currentIndex += 1
        }
        
        print("🔄 Moved '\(song.title)' from position \(sourceIndex) to \(destinationIndex)")
    }
    
    /// Clear entire queue
    func clearQueue() {
        let songCount = queue.count
        queue.removeAll()
        currentIndex = 0
        stop()
        print("🗑️ Cleared queue (\(songCount) songs removed)")
    }
    
    /// Shuffle current queue
    func shuffleQueue() {
        guard !queue.isEmpty else { return }
        
        // Remember current song
        let currentSongId = currentSong?.id
        
        // Shuffle the queue
        queue.shuffle()
        
        // Update current index to match shuffled position
        if let songId = currentSongId,
           let newIndex = queue.firstIndex(where: { $0.id == songId }) {
            currentIndex = newIndex
        } else {
            currentIndex = 0
        }
        
        print("🔀 Queue shuffled")
    }
}

// MARK: - Private Helper Methods
private extension MusicPlayerManager {
    
    /// Simulate audio playback for demo purposes
    func simulateAudioPlayback(for song: Song) {
        // In a real app, you'd load from song.audioURL
        // For demo, we'll use a silent audio file or simulate
        
        duration = song.duration
        currentTime = 0
        playerState = .playing
        startProgressTimer()
        
        print("🎵 Simulating playback for: \(song.title)")
    }
    
    /// Start timer for progress updates
    func startProgressTimer() {
        stopProgressTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    /// Stop progress timer
    func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Update playback progress
    func updateProgress() {
        guard playerState == .playing else { return }
        
        currentTime += 0.1
        
        // Check if song finished
        if currentTime >= duration {
            handleSongFinished()
        }
    }
    
    /// Handle when current song finishes
    func handleSongFinished() {
        switch playbackMode {
        case .normal:
            if currentIndex < queue.count - 1 {
                playNext()
            } else {
                stop()
            }
        case .repeatOne:
            seek(to: 0)
            play()
        case .repeatAll, .shuffle:
            playNext()
        }
    }
    
    /// Handle app entering background
    func handleAppDidEnterBackground() {
        // Continue playing in background (if audio session is configured correctly)
        print("📱 App entered background - music continues")
    }
    
    /// Handle app entering foreground
    func handleAppWillEnterForeground() {
        print("📱 App entered foreground")
    }
}

// MARK: - Music Source Management
extension MusicPlayerManager {
    
    /// Fetch songs from all available sources
    func fetchSongsFromAllSources() async -> [Song] {
        print("🔍 Fetching songs from all sources...")
        
        var allSongs: [Song] = []
        
        // Use TaskGroup to fetch from all sources concurrently
        await withTaskGroup(of: [Song].self) { group in
            for source in musicSources {
                group.addTask {
                    do {
                        let isAvailable = await source.isAvailable()
                        if isAvailable {
                            return try await source.fetchSongs()
                        } else {
                            print("⚠️ \(source.sourceType.rawValue) is not available")
                            return []
                        }
                    } catch {
                        print("❌ Error fetching from \(source.sourceType.rawValue): \(error)")
                        return []
                    }
                }
            }
            
            for await songs in group {
                allSongs.append(contentsOf: songs)
            }
        }
        
        print("✅ Fetched \(allSongs.count) songs total")
        return allSongs
    }
    
    /// Search songs across all sources
    func searchSongs(query: String) async -> [Song] {
        guard !query.isEmpty else { return [] }
        
        var searchResults: [Song] = []
        
        await withTaskGroup(of: [Song].self) { group in
            for source in musicSources {
                group.addTask {
                    do {
                        return try await source.searchSongs(query: query)
                    } catch {
                        print("❌ Search error in \(source.sourceType.rawValue): \(error)")
                        return []
                    }
                }
            }
            
            for await songs in group {
                searchResults.append(contentsOf: songs)
            }
        }
        
        return searchResults
    }
}
