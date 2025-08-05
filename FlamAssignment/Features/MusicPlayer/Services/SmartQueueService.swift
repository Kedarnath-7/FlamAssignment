import Foundation

// MARK: - Smart Queue Service
/// Queue management with suggestions
class SmartQueueService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var smartSuggestions: [Song] = []
    @Published var isGeneratingSuggestions = false
    
    // MARK: - Private Properties
    private var allSongs: [Song] = []
    private var listeningHistory: [Song] = []
    private let maxSuggestions = 10
    
    // MARK: - Singleton
    static let shared = SmartQueueService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Update available songs for suggestions
    func updateAvailableSongs(_ songs: [Song]) {
        self.allSongs = songs
    }
    
    /// Generate smart suggestions based on current song and context
    func generateSmartSuggestions(for currentSong: Song?, context: QueueContext = .general) {
        guard !allSongs.isEmpty else { return }
        
        isGeneratingSuggestions = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let suggestions = self.calculateSmartSuggestions(
                currentSong: currentSong,
                context: context
            )
            
            DispatchQueue.main.async {
                self.smartSuggestions = suggestions
                self.isGeneratingSuggestions = false
            }
        }
    }
    
    /// Get suggestions for similar songs
    func getSimilarSongs(to song: Song, limit: Int = 5) -> [Song] {
        return allSongs
            .filter { $0.id != song.id }
            .sorted { song1, song2 in
                calculateSimilarity(between: song, and: song1) >
                calculateSimilarity(between: song, and: song2)
            }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get mood-based suggestions
    func getMoodBasedSuggestions(mood: MoodTag, limit: Int = 10) -> [Song] {
        return allSongs
            .filter { $0.mood == mood }
            .shuffled()
            .prefix(limit)
            .map { $0 }
    }
    
    /// Add song to listening history for better suggestions
    func addToHistory(_ song: Song) {
        listeningHistory.append(song)
        
        // Keep only last 50 songs in history
        if listeningHistory.count > 50 {
            listeningHistory.removeFirst()
        }
    }
    
    /// Get energy-based transitions
    func getEnergyBasedNext(for currentSong: Song, targetDirection: EnergyDirection) -> [Song] {
        guard let currentEnergy = currentSong.energy else {
            return allSongs.shuffled().prefix(5).map { $0 }
        }
        
        let targetRange: ClosedRange<Float>
        
        switch targetDirection {
        case .higher:
            targetRange = min(currentEnergy + 0.1, 1.0)...1.0
        case .lower:
            targetRange = 0.0...max(currentEnergy - 0.1, 0.0)
        case .similar:
            targetRange = max(currentEnergy - 0.2, 0.0)...min(currentEnergy + 0.2, 1.0)
        }
        
        return allSongs
            .filter { song in
                guard let energy = song.energy else { return false }
                return targetRange.contains(energy) && song.id != currentSong.id
            }
            .shuffled()
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func calculateSmartSuggestions(currentSong: Song?, context: QueueContext) -> [Song] {
        var suggestions: [Song] = []
        var weights: [String: Float] = [:]
        
        // Weight songs based on various factors
        for song in allSongs {
            guard song.id != currentSong?.id else { continue }
            
            var weight: Float = 0.0
            
            // Factor 1: Similarity to current song
            if let current = currentSong {
                weight += calculateSimilarity(between: current, and: song) * 0.3
            }
            
            // Factor 2: Historical preferences
            weight += calculateHistoryWeight(for: song) * 0.2
            
            // Factor 3: Context-based scoring
            weight += calculateContextWeight(for: song, context: context) * 0.3
            
            // Factor 4: Variety factor (avoid repetition)
            weight += calculateVarietyBonus(for: song) * 0.2
            
            weights[song.id] = weight
        }
        
        // Sort by weight and take top suggestions
        suggestions = allSongs
            .filter { weights[$0.id] != nil }
            .sorted { weights[$0.id]! > weights[$1.id]! }
            .prefix(maxSuggestions)
            .map { $0 }
        
        return suggestions
    }
    
    private func calculateSimilarity(between song1: Song, and song2: Song) -> Float {
        var similarity: Float = 0.0
        
        // Same artist bonus
        if song1.artist.lowercased() == song2.artist.lowercased() {
            similarity += 0.4
        }
        
        // Same album bonus
        if let album1 = song1.album, let album2 = song2.album,
           album1.lowercased() == album2.lowercased() {
            similarity += 0.3
        }
        
        // Same source bonus
        if song1.source == song2.source {
            similarity += 0.1
        }
        
        // Same mood bonus
        if let mood1 = song1.mood, let mood2 = song2.mood, mood1 == mood2 {
            similarity += 0.2
        }
        
        // Similar energy levels
        if let energy1 = song1.energy, let energy2 = song2.energy {
            let energyDiff = abs(energy1 - energy2)
            similarity += (1.0 - energyDiff) * 0.2
        }
        
        // Same genre bonus
        if let genre1 = song1.genre, let genre2 = song2.genre,
           genre1.lowercased() == genre2.lowercased() {
            similarity += 0.3
        }
        
        return min(similarity, 1.0)
    }
    
    private func calculateHistoryWeight(for song: Song) -> Float {
        let recentPlays = listeningHistory.suffix(20)
        
        // Check for artist frequency
        let artistCount = recentPlays.filter { $0.artist.lowercased() == song.artist.lowercased() }.count
        
        // Check for mood frequency
        let moodCount = recentPlays.compactMap { $0.mood }.filter { $0 == song.mood }.count
        
        // Boost songs from frequently played artists and moods
        let artistWeight = Float(artistCount) / 20.0 * 0.5
        let moodWeight = Float(moodCount) / 20.0 * 0.3
        
        // Reduce weight if song was played very recently
        if recentPlays.suffix(5).contains(where: { $0.id == song.id }) {
            return max(0, artistWeight + moodWeight - 0.5)
        }
        
        return artistWeight + moodWeight
    }
    
    private func calculateContextWeight(for song: Song, context: QueueContext) -> Float {
        switch context {
        case .general:
            return 0.0
        case .workout:
            if let energy = song.energy, energy > 0.7 {
                return 0.8
            }
            if song.mood == .energetic || song.mood == .upbeat {
                return 0.6
            }
            return 0.0
        case .focus:
            if song.mood == .focus || song.mood == .chill {
                return 0.8
            }
            if let energy = song.energy, energy < 0.5 {
                return 0.4
            }
            return 0.0
        case .party:
            if song.mood == .party || song.mood == .upbeat {
                return 0.8
            }
            if let energy = song.energy, energy > 0.6 {
                return 0.6
            }
            return 0.0
        case .relaxing:
            if song.mood == .relaxing || song.mood == .chill {
                return 0.8
            }
            if let energy = song.energy, energy < 0.4 {
                return 0.6
            }
            return 0.0
        }
    }
    
    private func calculateVarietyBonus(for song: Song) -> Float {
        let recentHistory = listeningHistory.suffix(10)
        
        // Boost if artist hasn't been played recently
        let hasRecentArtist = recentHistory.contains { $0.artist.lowercased() == song.artist.lowercased() }
        let artistBonus: Float = hasRecentArtist ? 0.0 : 0.3
        
        // Boost if genre hasn't been played recently
        let hasRecentGenre = recentHistory.contains { $0.genre?.lowercased() == song.genre?.lowercased() }
        let genreBonus: Float = hasRecentGenre ? 0.0 : 0.2
        
        return artistBonus + genreBonus
    }
}

// MARK: - Supporting Types

enum QueueContext {
    case general
    case workout
    case focus
    case party
    case relaxing
}

enum EnergyDirection {
    case higher
    case lower
    case similar
}
