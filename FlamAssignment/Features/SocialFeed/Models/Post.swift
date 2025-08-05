import Foundation
import SwiftUI

// MARK: - Post Models

struct User: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let isVerified: Bool
    let followersCount: Int
    
    init(id: String = UUID().uuidString, 
         username: String, 
         displayName: String, 
         avatarURL: String? = nil, 
         isVerified: Bool = false, 
         followersCount: Int = 0) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isVerified = isVerified
        self.followersCount = followersCount
    }
}

enum PostType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case poll = "poll"
    case repost = "repost"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .video: return "Video"
        case .poll: return "Poll"
        case .repost: return "Repost"
        }
    }
}

struct PostMedia: Codable, Identifiable, Equatable {
    let id: String
    let type: MediaType
    let url: String
    let thumbnailURL: String?
    let width: Int?
    let height: Int?
    let duration: TimeInterval? // For videos
    
    enum MediaType: String, Codable {
        case image = "image"
        case video = "video"
        case gif = "gif"
    }
    
    init(id: String = UUID().uuidString,
         type: MediaType,
         url: String,
         thumbnailURL: String? = nil,
         width: Int? = nil,
         height: Int? = nil,
         duration: TimeInterval? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.width = width
        self.height = height
        self.duration = duration
    }
}

struct PollOption: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let voteCount: Int
    
    init(id: String = UUID().uuidString, text: String, voteCount: Int = 0) {
        self.id = id
        self.text = text
        self.voteCount = voteCount
    }
}

struct Poll: Codable, Equatable {
    let question: String
    let options: [PollOption]
    let totalVotes: Int
    let endsAt: Date?
    let userVote: String? // Option ID the user voted for
    
    var isExpired: Bool {
        guard let endsAt = endsAt else { return false }
        return Date() > endsAt
    }
}

struct Post: Codable, Identifiable, Equatable {
    let id: String
    let user: User
    let type: PostType
    let content: String
    let media: [PostMedia]
    let poll: Poll?
    let repostedPostId: String? // Changed from Post? to String? to avoid recursion
    let createdAt: Date
    let updatedAt: Date?
    
    // Engagement metrics
    let likeCount: Int
    let repostCount: Int
    let replyCount: Int
    let viewCount: Int
    
    // User interaction state
    let isLiked: Bool
    let isReposted: Bool
    let isBookmarked: Bool
    
    // Metadata
    let hashtags: [String]
    let mentions: [String]
    let isPromoted: Bool
    let isPinned: Bool
    
    init(id: String = UUID().uuidString,
         user: User,
         type: PostType = .text,
         content: String,
         media: [PostMedia] = [],
         poll: Poll? = nil,
         repostedPostId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date? = nil,
         likeCount: Int = 0,
         repostCount: Int = 0,
         replyCount: Int = 0,
         viewCount: Int = 0,
         isLiked: Bool = false,
         isReposted: Bool = false,
         isBookmarked: Bool = false,
         hashtags: [String] = [],
         mentions: [String] = [],
         isPromoted: Bool = false,
         isPinned: Bool = false) {
        self.id = id
        self.user = user
        self.type = type
        self.content = content
        self.media = media
        self.poll = poll
        self.repostedPostId = repostedPostId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.viewCount = viewCount
        self.isLiked = isLiked
        self.isReposted = isReposted
        self.isBookmarked = isBookmarked
        self.hashtags = hashtags
        self.mentions = mentions
        self.isPromoted = isPromoted
        self.isPinned = isPinned
    }
    
    // Computed properties
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedLikeCount: String {
        return formatCount(likeCount)
    }
    
    var formattedRepostCount: String {
        return formatCount(repostCount)
    }
    
    var formattedReplyCount: String {
        return formatCount(replyCount)
    }
    
    private func formatCount(_ count: Int) -> String {
        switch count {
        case 0:
            return ""
        case 1..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            return String(format: "%.1fK", Double(count) / 1000)
        default:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
    }
}

// MARK: - Feed State Models

enum FeedState {
    case idle
    case loading
    case loaded([Post])
    case refreshing([Post])
    case loadingMore([Post])
    case error(String)
    
    var posts: [Post] {
        switch self {
        case .idle:
            return []
        case .loading:
            return []
        case .loaded(let posts):
            return posts
        case .refreshing(let posts):
            return posts
        case .loadingMore(let posts):
            return posts
        case .error:
            return []
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing, .loadingMore:
            return true
        default:
            return false
        }
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Plugin System Models

protocol FeedItemPlugin {
    var id: String { get }
    var name: String { get }
    var supportedPostTypes: [PostType] { get }
    
    func canHandle(post: Post) -> Bool
    func createView(for post: Post) -> any View
    func calculateHeight(for post: Post, width: CGFloat) -> CGFloat
}

struct PluginRegistry {
    private var plugins: [String: FeedItemPlugin] = [:]
    
    mutating func register(_ plugin: FeedItemPlugin) {
        plugins[plugin.id] = plugin
    }
    
    func findPlugin(for post: Post) -> FeedItemPlugin? {
        return plugins.values.first { $0.canHandle(post: post) }
    }
    
    func allPlugins() -> [FeedItemPlugin] {
        return Array(plugins.values)
    }
}
