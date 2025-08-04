import Foundation

// MARK: - Network Service
/// Handles all network requests for music data
/// Uses the free APIs provided in the assignment
class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    // MARK: - API Endpoints
    private enum Endpoints {
        static let audioDBBase = "https://www.theaudiodb.com/api/v1/json/2"
        static let discogsBase = "https://api.discogs.com"
        
        static func searchArtist(_ query: String) -> String {
            return "\(audioDBBase)/search.php?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        static func searchAlbum(_ query: String) -> String {
            return "\(audioDBBase)/searchalbum.php?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        static func discogsSearch(_ query: String) -> String {
            return "\(discogsBase)/database/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=release&key=your_key&secret=your_secret"
        }
    }
    
    // MARK: - API Response Models
    struct AudioDBResponse: Codable {
        let artists: [AudioDBArtist]?
        let album: [AudioDBAlbum]?
    }
    
    struct AudioDBArtist: Codable {
        let idArtist: String?
        let strArtist: String?
        let strGenre: String?
        let strArtistThumb: String?
        let strBiographyEN: String?
    }
    
    struct AudioDBAlbum: Codable {
        let idAlbum: String?
        let strAlbum: String?
        let strArtist: String?
        let intYearReleased: String?
        let strAlbumThumb: String?
        let strGenre: String?
        let strDescriptionEN: String?
    }
    
    struct DiscogsResponse: Codable {
        let results: [DiscogsRelease]?
    }
    
    struct DiscogsRelease: Codable {
        let id: Int
        let title: String
        let year: Int?
        let genre: [String]?
        let thumb: String?
        let master_url: String?
    }
}

// MARK: - Network Methods
extension NetworkService {
    
    /// Fetch songs from AudioDB API
    func fetchSongsFromAudioDB(query: String = "rock") async throws -> [Song] {
        let urlString = Endpoints.searchAlbum(query)
        guard let url = URL(string: urlString) else {
            throw AppError.networkError("Invalid URL")
        }
        
        print("🌐 Fetching from AudioDB: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AppError.networkError("HTTP Error")
        }
        
        let audioDBResponse = try JSONDecoder().decode(AudioDBResponse.self, from: data)
        
        return convertAudioDBToSongs(audioDBResponse.album ?? [])
    }
    
    /// Fetch songs from Discogs API (mock - requires authentication)
    func fetchSongsFromDiscogs(query: String = "electronic") async throws -> [Song] {
        // For demo purposes, we'll return mock data since Discogs requires authentication
        // In a real app, you'd implement OAuth flow
        
        print("🌐 Fetching from Discogs (mock): \(query)")
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            Song(
                title: "One More Time",
                artist: "Daft Punk",
                album: "Discovery",
                duration: 320,
                source: .spotify
            ),
            Song(
                title: "Around the World",
                artist: "Daft Punk",
                album: "Homework",
                duration: 428,
                source: .spotify
            ),
            Song(
                title: "Get Lucky",
                artist: "Daft Punk",
                album: "Random Access Memories",
                duration: 367,
                source: .spotify
            )
        ]
    }
    
    /// Search across all APIs
    func searchAllAPIs(query: String) async -> [Song] {
        var allSongs: [Song] = []
        
        await withTaskGroup(of: [Song].self) { group in
            // AudioDB search
            group.addTask {
                do {
                    return try await self.fetchSongsFromAudioDB(query: query)
                } catch {
                    print("❌ AudioDB error: \(error)")
                    return []
                }
            }
            
            // Discogs search (mock)
            group.addTask {
                do {
                    return try await self.fetchSongsFromDiscogs(query: query)
                } catch {
                    print("❌ Discogs error: \(error)")
                    return []
                }
            }
            
            for await songs in group {
                allSongs.append(contentsOf: songs)
            }
        }
        
        return allSongs
    }
}

// MARK: - Data Conversion
private extension NetworkService {
    
    func convertAudioDBToSongs(_ albums: [AudioDBAlbum]) -> [Song] {
        return albums.compactMap { album in
            guard let albumName = album.strAlbum,
                  let artistName = album.strArtist else { return nil }
            
            // Generate realistic duration (3-5 minutes)
            let duration = TimeInterval.random(in: 180...300)
            
            return Song(
                title: albumName,
                artist: artistName,
                album: albumName,
                duration: duration,
                artworkURL: URL(string: album.strAlbumThumb ?? ""),
                source: .local
            )
        }
    }
}
