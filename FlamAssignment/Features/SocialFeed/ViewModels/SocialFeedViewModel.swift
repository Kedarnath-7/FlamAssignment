import Foundation
import Combine
import SwiftUI

class SocialFeedViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var feedState: FeedState = .idle
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var hasMorePosts = true
    
    // MARK: - Private Properties
    private let feedService: SocialFeedServiceProtocol
    private var currentPage = 0
    private let pageSize = 10
    private var pluginRegistry = PluginRegistry()
    
    // MARK: - Combine Publishers
    var postsPublisher: AnyPublisher<[Post], Never> {
        $feedState
            .map { $0.posts }
            .eraseToAnyPublisher()
    }
    
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $feedState
            .map { $0.isLoading }
            .eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $feedState
            .map { $0.errorMessage }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(feedService: SocialFeedServiceProtocol = MockSocialFeedService()) {
        self.feedService = feedService
        super.init()
        
        setupPlugins()
        loadInitialPosts()
    }
    
    // MARK: - Public Methods
    
    func refreshFeed() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        Task { @MainActor in
            do {
                feedState = .refreshing(feedState.posts)
                let newPosts = try await feedService.refreshFeed()
                currentPage = 0
                hasMorePosts = newPosts.count == pageSize
                feedState = .loaded(newPosts)
            } catch {
                feedState = .error(error.localizedDescription)
            }
            isRefreshing = false
        }
    }
    
    func loadMorePosts() {
        guard !isLoadingMore && hasMorePosts && !feedState.isLoading else { return }
        
        isLoadingMore = true
        
        Task { @MainActor in
            do {
                feedState = .loadingMore(feedState.posts)
                currentPage += 1
                let newPosts = try await feedService.fetchPosts(page: currentPage, pageSize: pageSize)
                
                if newPosts.isEmpty {
                    hasMorePosts = false
                    feedState = .loaded(feedState.posts)
                } else {
                    let allPosts = feedState.posts + newPosts
                    hasMorePosts = newPosts.count == pageSize
                    feedState = .loaded(allPosts)
                }
            } catch {
                currentPage = max(0, currentPage - 1)
                feedState = .error(error.localizedDescription)
            }
            isLoadingMore = false
        }
    }
    
    func likePost(_ post: Post) {
        Task { @MainActor in
            do {
                let updatedPost: Post
                if post.isLiked {
                    updatedPost = try await feedService.unlikePost(id: post.id)
                } else {
                    updatedPost = try await feedService.likePost(id: post.id)
                }
                updatePost(updatedPost)
            } catch {
                // Handle error - could show toast or alert
            }
        }
    }
    
    func repost(_ post: Post) {
        Task { @MainActor in
            do {
                let updatedPost: Post
                if post.isReposted {
                    updatedPost = try await feedService.unrepost(id: post.id)
                } else {
                    updatedPost = try await feedService.repost(id: post.id)
                }
                updatePost(updatedPost)
            } catch {
                // Handle error
            }
        }
    }
    
    func bookmarkPost(_ post: Post) {
        Task { @MainActor in
            do {
                let updatedPost: Post
                if post.isBookmarked {
                    updatedPost = try await feedService.unbookmarkPost(id: post.id)
                } else {
                    updatedPost = try await feedService.bookmarkPost(id: post.id)
                }
                updatePost(updatedPost)
            } catch {
                // Handle error
            }
        }
    }
    
    func sharePost(_ post: Post) {
        // Implementation for sharing
    }
    
    func reportPost(_ post: Post) {
        // Implementation for reporting
    }
    
    // MARK: - Plugin System
    
    func registerPlugin(_ plugin: FeedItemPlugin) {
        pluginRegistry.register(plugin)
    }
    
    func getPlugin(for post: Post) -> FeedItemPlugin? {
        return pluginRegistry.findPlugin(for: post)
    }
    
    func calculatePostHeight(for post: Post, width: CGFloat) -> CGFloat {
        if let plugin = getPlugin(for: post) {
            return plugin.calculateHeight(for: post, width: width)
        }
        
        // Default height calculation
        return calculateDefaultHeight(for: post, width: width)
    }
    
    // MARK: - Private Methods
    
    private func loadInitialPosts() {
        feedState = .loading
        
        Task { @MainActor in
            do {
                let posts = try await feedService.fetchPosts(page: 0, pageSize: pageSize)
                currentPage = 0
                hasMorePosts = posts.count == pageSize
                feedState = .loaded(posts)
            } catch {
                feedState = .error(error.localizedDescription)
            }
        }
    }
    
    private func updatePost(_ updatedPost: Post) {
        guard case .loaded(let posts) = feedState else { return }
        
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            var updatedPosts = posts
            updatedPosts[index] = updatedPost
            feedState = .loaded(updatedPosts)
        }
    }
    
    private func setupPlugins() {
        // Register default plugins
        registerPlugin(TextPostPlugin())
        registerPlugin(ImagePostPlugin())
        registerPlugin(VideoPostPlugin())
        registerPlugin(PollPostPlugin())
    }
    
    private func calculateDefaultHeight(for post: Post, width: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 120 // Header + footer
        let contentPadding: CGFloat = 32
        let availableWidth = width - contentPadding
        
        // Calculate content height
        let contentHeight = estimateTextHeight(post.content, width: availableWidth)
        
        // Add media height if present
        var mediaHeight: CGFloat = 0
        if !post.media.isEmpty {
            mediaHeight = 200 // Default media height
        }
        
        // Add poll height if present
        var pollHeight: CGFloat = 0
        if let poll = post.poll {
            pollHeight = CGFloat(poll.options.count * 40 + 60) // Option height + padding
        }
        
        return baseHeight + contentHeight + mediaHeight + pollHeight
    }
    
    private func estimateTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        let rect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.height) + 16 // Add some padding
    }
}

// MARK: - Default Plugins

struct TextPostPlugin: FeedItemPlugin {
    let id = "text_post_plugin"
    let name = "Text Post Plugin"
    let supportedPostTypes: [PostType] = [.text]
    
    func canHandle(post: Post) -> Bool {
        return post.type == .text && post.media.isEmpty && post.poll == nil
    }
    
    func createView(for post: Post) -> any View {
        Text("Text Post Plugin View") // Placeholder
    }
    
    func calculateHeight(for post: Post, width: CGFloat) -> CGFloat {
        // Calculate height for text-only posts
        let baseHeight: CGFloat = 120
        let contentHeight = estimateTextHeight(post.content, width: width - 32)
        return baseHeight + contentHeight
    }
    
    private func estimateTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        let rect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.height) + 16
    }
}

struct ImagePostPlugin: FeedItemPlugin {
    let id = "image_post_plugin"
    let name = "Image Post Plugin"
    let supportedPostTypes: [PostType] = [.image]
    
    func canHandle(post: Post) -> Bool {
        return post.type == .image || (!post.media.isEmpty && post.media.first?.type == .image)
    }
    
    func createView(for post: Post) -> any View {
        Text("Image Post Plugin View") // Placeholder
    }
    
    func calculateHeight(for post: Post, width: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 120
        let mediaHeight: CGFloat = 250
        let contentHeight = estimateTextHeight(post.content, width: width - 32)
        return baseHeight + contentHeight + mediaHeight
    }
    
    private func estimateTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        let rect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.height) + 16
    }
}

struct VideoPostPlugin: FeedItemPlugin {
    let id = "video_post_plugin"
    let name = "Video Post Plugin"
    let supportedPostTypes: [PostType] = [.video]
    
    func canHandle(post: Post) -> Bool {
        return post.type == .video || (!post.media.isEmpty && post.media.first?.type == .video)
    }
    
    func createView(for post: Post) -> any View {
        Text("Video Post Plugin View") // Placeholder
    }
    
    func calculateHeight(for post: Post, width: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 120
        let mediaHeight: CGFloat = 225 // 16:9 aspect ratio
        let contentHeight = estimateTextHeight(post.content, width: width - 32)
        return baseHeight + contentHeight + mediaHeight
    }
    
    private func estimateTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        let rect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.height) + 16
    }
}

struct PollPostPlugin: FeedItemPlugin {
    let id = "poll_post_plugin"
    let name = "Poll Post Plugin"
    let supportedPostTypes: [PostType] = [.poll]
    
    func canHandle(post: Post) -> Bool {
        return post.type == .poll && post.poll != nil
    }
    
    func createView(for post: Post) -> any View {
        Text("Poll Post Plugin View") // Placeholder
    }
    
    func calculateHeight(for post: Post, width: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 120
        let contentHeight = estimateTextHeight(post.content, width: width - 32)
        
        var pollHeight: CGFloat = 0
        if let poll = post.poll {
            pollHeight = CGFloat(poll.options.count * 50 + 80) // Options + question + metadata
        }
        
        return baseHeight + contentHeight + pollHeight
    }
    
    private func estimateTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        let rect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.height) + 16
    }
}
