import Foundation
import Combine

// MARK: - Social Feed Service Protocol

protocol SocialFeedServiceProtocol {
    func fetchPosts(page: Int, pageSize: Int) async throws -> [Post]
    func refreshFeed() async throws -> [Post]
    func likePost(id: String) async throws -> Post
    func unlikePost(id: String) async throws -> Post
    func repost(id: String) async throws -> Post
    func unrepost(id: String) async throws -> Post
    func bookmarkPost(id: String) async throws -> Post
    func unbookmarkPost(id: String) async throws -> Post
}

// MARK: - Mock Social Feed Service

class MockSocialFeedService: SocialFeedServiceProtocol {
    private let networkDelay: TimeInterval = 1.0
    private var currentPage = 0
    private let pageSize = 10
    
    // Mock data storage
    private var posts: [Post] = []
    private var likedPosts: Set<String> = []
    private var repostedPosts: Set<String> = []
    private var bookmarkedPosts: Set<String> = []
    
    init() {
        generateMockData()
    }
    
    func fetchPosts(page: Int, pageSize: Int) async throws -> [Post] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, posts.count)
        
        guard startIndex < posts.count else {
            return []
        }
        
        return Array(posts[startIndex..<endIndex])
    }
    
    func refreshFeed() async throws -> [Post] {
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        // Simulate new posts at the top
        let newPosts = generateNewPosts(count: 3)
        posts = newPosts + posts
        
        return Array(posts.prefix(pageSize))
    }
    
    func likePost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        likedPosts.insert(id)
        let updatedPost = updatePostEngagement(posts[index], likeCount: posts[index].likeCount + 1, isLiked: true)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    func unlikePost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        likedPosts.remove(id)
        let updatedPost = updatePostEngagement(posts[index], likeCount: max(0, posts[index].likeCount - 1), isLiked: false)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    func repost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        repostedPosts.insert(id)
        let updatedPost = updatePostEngagement(posts[index], repostCount: posts[index].repostCount + 1, isReposted: true)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    func unrepost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        repostedPosts.remove(id)
        let updatedPost = updatePostEngagement(posts[index], repostCount: max(0, posts[index].repostCount - 1), isReposted: false)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    func bookmarkPost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        bookmarkedPosts.insert(id)
        let updatedPost = updatePostEngagement(posts[index], isBookmarked: true)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    func unbookmarkPost(id: String) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw SocialFeedError.postNotFound
        }
        
        bookmarkedPosts.remove(id)
        let updatedPost = updatePostEngagement(posts[index], isBookmarked: false)
        posts[index] = updatedPost
        
        return updatedPost
    }
    
    // MARK: - Private Helpers
    
    private func updatePostEngagement(_ post: Post, 
                                    likeCount: Int? = nil,
                                    repostCount: Int? = nil,
                                    replyCount: Int? = nil,
                                    isLiked: Bool? = nil,
                                    isReposted: Bool? = nil,
                                    isBookmarked: Bool? = nil) -> Post {
        return Post(
            id: post.id,
            user: post.user,
            type: post.type,
            content: post.content,
            media: post.media,
            poll: post.poll,
            repostedPostId: post.repostedPostId,
            createdAt: post.createdAt,
            updatedAt: Date(),
            likeCount: likeCount ?? post.likeCount,
            repostCount: repostCount ?? post.repostCount,
            replyCount: replyCount ?? post.replyCount,
            viewCount: post.viewCount,
            isLiked: isLiked ?? post.isLiked,
            isReposted: isReposted ?? post.isReposted,
            isBookmarked: isBookmarked ?? post.isBookmarked,
            hashtags: post.hashtags,
            mentions: post.mentions,
            isPromoted: post.isPromoted,
            isPinned: post.isPinned
        )
    }
    
    private func generateMockData() {
        let users = createMockUsers()
        posts = createMockPosts(users: users)
    }
    
    private func createMockUsers() -> [User] {
        return [
            User(username: "tech_guru", displayName: "Tech Guru", avatarURL: "https://picsum.photos/100/100?random=1", isVerified: true, followersCount: 125000),
            User(username: "jane_dev", displayName: "Jane Developer", avatarURL: "https://picsum.photos/100/100?random=2", isVerified: false, followersCount: 5420),
            User(username: "ios_expert", displayName: "iOS Expert", avatarURL: "https://picsum.photos/100/100?random=3", isVerified: true, followersCount: 89000),
            User(username: "swift_ninja", displayName: "Swift Ninja", avatarURL: "https://picsum.photos/100/100?random=4", isVerified: false, followersCount: 12300),
            User(username: "ui_designer", displayName: "UI/UX Designer", avatarURL: "https://picsum.photos/100/100?random=5", isVerified: true, followersCount: 67000),
            User(username: "code_artist", displayName: "Code Artist", avatarURL: "https://picsum.photos/100/100?random=6", isVerified: false, followersCount: 3210),
            User(username: "mobile_master", displayName: "Mobile Master", avatarURL: "https://picsum.photos/100/100?random=7", isVerified: true, followersCount: 156000),
            User(username: "app_builder", displayName: "App Builder", avatarURL: "https://picsum.photos/100/100?random=8", isVerified: false, followersCount: 8750)
        ]
    }
    
    private func createMockPosts(users: [User]) -> [Post] {
        var mockPosts: [Post] = []
        
        // Text posts
        mockPosts.append(Post(
            user: users[0],
            type: .text,
            content: "Just shipped a new feature using SwiftUI and Combine! The reactive programming paradigm really makes state management so much cleaner. 🚀 #SwiftUI #Combine #iOS",
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            likeCount: 127,
            repostCount: 23,
            replyCount: 15,
            viewCount: 1420,
            hashtags: ["SwiftUI", "Combine", "iOS"]
        ))
        
        // Image post
        mockPosts.append(Post(
            user: users[1],
            type: .image,
            content: "Check out this beautiful UI design I've been working on! Clean, minimal, and user-friendly. What do you think? ✨",
            media: [PostMedia(type: .image, url: "https://picsum.photos/400/300?random=10", width: 400, height: 300)],
            createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
            likeCount: 89,
            repostCount: 12,
            replyCount: 8,
            viewCount: 567
        ))
        
        // Poll post
        let pollOptions = [
            PollOption(text: "SwiftUI", voteCount: 156),
            PollOption(text: "UIKit", voteCount: 89),
            PollOption(text: "Flutter", voteCount: 23),
            PollOption(text: "React Native", voteCount: 45)
        ]
        let poll = Poll(question: "What's your favorite mobile development framework?", options: pollOptions, totalVotes: 313, endsAt: Calendar.current.date(byAdding: .day, value: 2, to: Date()), userVote: nil)
        
        mockPosts.append(Post(
            user: users[2],
            type: .poll,
            content: "Curious about the community's preferences! 🤔",
            poll: poll,
            createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
            likeCount: 245,
            repostCount: 67,
            replyCount: 89,
            viewCount: 2340
        ))
        
        // Video post
        mockPosts.append(Post(
            user: users[3],
            type: .video,
            content: "Here's a quick tutorial on implementing MVVM with Combine! Perfect for beginners 📱👨‍💻",
            media: [PostMedia(type: .video, url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4", thumbnailURL: "https://picsum.photos/400/225?random=11", width: 400, height: 225, duration: 180)],
            createdAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            likeCount: 678,
            repostCount: 234,
            replyCount: 156,
            viewCount: 5670
        ))
        
        // Continue with more diverse posts...
        for i in 4..<50 {
            let user = users[i % users.count]
            let randomType = PostType.allCases.randomElement() ?? .text
            
            let baseContent = [
                "Building amazing iOS apps with cutting-edge technology! 📱",
                "SwiftUI animations are getting smoother every day 🎨",
                "Clean code is not written by following a set of rules ✨",
                "The best way to learn is by building real projects 🛠️",
                "Performance optimization tips that changed my app 🚀",
                "Debugging is like being a detective in a crime movie 🔍",
                "Code review culture makes teams stronger 💪",
                "User experience should always come first 👥",
                "Accessibility in apps is not optional, it's essential ♿",
                "Testing saves time in the long run 🧪"
            ].randomElement() ?? "Great day for coding!"
            
            var media: [PostMedia] = []
            if randomType == .image {
                media.append(PostMedia(type: .image, url: "https://picsum.photos/400/300?random=\(i+20)", width: 400, height: 300))
            } else if randomType == .video {
                media.append(PostMedia(type: .video, url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4", thumbnailURL: "https://picsum.photos/400/225?random=\(i+30)", width: 400, height: 225, duration: Double.random(in: 30...300)))
            }
            
            mockPosts.append(Post(
                user: user,
                type: randomType == .poll ? .text : randomType, // Simplify for now
                content: baseContent,
                media: media,
                createdAt: Calendar.current.date(byAdding: .hour, value: -(i+1), to: Date()) ?? Date(),
                likeCount: Int.random(in: 0...1000),
                repostCount: Int.random(in: 0...200),
                replyCount: Int.random(in: 0...100),
                viewCount: Int.random(in: 100...10000)
            ))
        }
        
        return mockPosts.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func generateNewPosts(count: Int) -> [Post] {
        let users = createMockUsers()
        var newPosts: [Post] = []
        
        for i in 0..<count {
            let user = users.randomElement()!
            let content = [
                "Breaking: New iOS features announced! 🎉",
                "Just discovered an amazing new Swift package 📦",
                "Today's coding session was incredibly productive 💪",
                "Sharing some weekend project screenshots 📸",
                "Coffee + Code = Perfect Monday ☕"
            ].randomElement() ?? "New post!"
            
            newPosts.append(Post(
                user: user,
                type: .text,
                content: content,
                createdAt: Calendar.current.date(byAdding: .minute, value: -i*5, to: Date()) ?? Date(),
                likeCount: Int.random(in: 0...50),
                repostCount: Int.random(in: 0...10),
                replyCount: Int.random(in: 0...20),
                viewCount: Int.random(in: 50...500)
            ))
        }
        
        return newPosts
    }
}

// MARK: - Errors

enum SocialFeedError: LocalizedError {
    case postNotFound
    case networkError
    case unauthorized
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "Post not found"
        case .networkError:
            return "Network connection failed"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .serverError:
            return "Server error occurred"
        }
    }
}
