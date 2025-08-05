import Combine
import Foundation

// MARK: - MusicPlayerViewModel
/// ViewModel for the music player interface
/// Handles UI state and connects to MusicPlayerManager (business logic)
class MusicPlayerViewModel: BaseViewModel {
    
    // MARK: - Published Properties (UI State)
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var selectedSource: MusicSource = .local
    
    // MARK: - Dependencies
    private let musicManager = MusicPlayerManager.shared
    
    // MARK: - Computed Properties
    var currentSong: Song? { musicManager.currentSong }
    var playerState: PlayerState { musicManager.playerState }
    var currentTime: TimeInterval { musicManager.currentTime }
    var duration: TimeInterval { musicManager.duration }
    var isPlaying: Bool { musicManager.playerState.isPlaying }
    var playbackQueue: [Song] { musicManager.queue }
    var currentQueueIndex: Int { musicManager.currentIndex }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Listen to search text changes and search automatically
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                if searchText.isEmpty {
                    self?.loadSongs()
                } else {
                    self?.searchSongs(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Lifecycle
    override func onAppear() {
        super.onAppear()
        loadSongs()
    }
}

// MARK: - Public Methods
extension MusicPlayerViewModel {
    
    /// Load songs from selected source
    func loadSongs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let fetchedSongs = await musicManager.fetchSongsFromAllSources()
            
            await MainActor.run {
                self.songs = fetchedSongs
                self.isLoading = false
            }
        }
    }
    
    /// Search songs across all sources
    func searchSongs(query: String) {
        guard !query.isEmpty else {
            loadSongs()
            return
        }
        
        isLoading = true
        
        Task {
            let searchResults = await musicManager.searchSongs(query: query)
            
            await MainActor.run {
                self.songs = searchResults
                self.isLoading = false
            }
        }
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            musicManager.pause()
        } else {
            musicManager.play()
        }
    }
    
    /// Play all songs starting from a specific index
    func playAllSongs(startingFrom index: Int) {
        let songsToPlay = Array(songs[index...]) + Array(songs[..<index])
        musicManager.setQueue(songsToPlay, startIndex: 0)
    }
    
    /// Play a specific song
    func playSong(_ song: Song) {
        musicManager.play(song: song)
    }
    
    /// Seek to position in current song
    func seekTo(position: Double) {
        let time = position * duration
        musicManager.seek(to: time)
    }
    
    // MARK: - Queue Management
    /// Add song to queue
    func addSongToQueue(_ song: Song) {
        musicManager.addToQueue(song)
    }
    
    /// Remove song from queue
    func removeSongFromQueue(_ song: Song) {
        musicManager.removeFromQueue(song)
    }
    
    /// Remove song at specific index
    func removeSongFromQueue(at index: Int) {
        musicManager.removeFromQueue(at: index)
    }
    
    /// Reorder songs in queue
    func reorderSongs(from sourceIndex: Int, to destinationIndex: Int) {
        musicManager.reorderInQueue(from: sourceIndex, to: destinationIndex)
    }
    
    /// Clear entire queue
    func clearQueue() {
        musicManager.clearQueue()
    }
    
    /// Shuffle current queue
    func shuffleQueue() {
        musicManager.shuffleQueue()
    }
}
