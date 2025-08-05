import SwiftUI
import Combine

struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel()
    @State private var selectedPost: Post?
    @State private var showingPostDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                switch viewModel.feedState {
                case .idle, .loading:
                    LoadingView()
                    
                case .loaded(let posts), .refreshing(let posts), .loadingMore(let posts):
                    feedContent(posts: posts)
                    
                case .error(let message):
                    ErrorView(message: message) {
                        viewModel.refreshFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshFeed()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primary)
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
            .sheet(isPresented: $showingPostDetail) {
                if let post = selectedPost {
                    PostDetailView(post: post)
                }
            }
        }
    }
    
    @ViewBuilder
    private func feedContent(posts: [Post]) -> some View {
        if posts.isEmpty {
            EmptyFeedView()
        } else {
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(posts) { post in
                        FeedItemView(
                            post: post,
                            onLike: {
                                viewModel.likePost(post)
                            },
                            onRepost: {
                                viewModel.repost(post)
                            },
                            onBookmark: {
                                viewModel.bookmarkPost(post)
                            },
                            onShare: {
                                viewModel.sharePost(post)
                            }
                        )
                        .background(Color(.systemBackground))
                        .onTapGesture {
                            selectedPost = post
                            showingPostDetail = true
                        }
                        .onAppear {
                            // Load more when approaching the end
                            if post == posts.last {
                                viewModel.loadMorePosts()
                            }
                        }
                        
                        // Separator
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 1)
                    }
                    
                    // Load more indicator
                    if viewModel.isLoadingMore {
                        LoadMoreView()
                    } else if !viewModel.hasMorePosts && posts.count > 10 {
                        Text("You're all caught up!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .refreshable {
                viewModel.refreshFeed()
            }
        }
    }
}

// MARK: - Post Detail View

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SocialFeedViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Main post
                    FeedItemView(
                        post: post,
                        onLike: {
                            viewModel.likePost(post)
                        },
                        onRepost: {
                            viewModel.repost(post)
                        },
                        onBookmark: {
                            viewModel.bookmarkPost(post)
                        },
                        onShare: {
                            viewModel.sharePost(post)
                        }
                    )
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Comments/Replies section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Replies")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Mock replies
                        ForEach(0..<3, id: \.self) { index in
                            ReplyView(replyIndex: index)
                                .padding(.horizontal)
                        }
                        
                        Text("End of replies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.sharePost(post)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Reply View

struct ReplyView: View {
    let replyIndex: Int
    
    private var mockReplies: [(String, String)] {
        [
            ("john_doe", "Great post! Really insightful 👏"),
            ("tech_enthusiast", "Thanks for sharing this. I learned something new today."),
            ("swift_developer", "This is exactly what I needed to understand MVVM better!")
        ]
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(mockReplies[replyIndex].0.prefix(1)).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mockReplies[replyIndex].0)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("2h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                Text(mockReplies[replyIndex].1)
                    .font(.body)
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.caption)
                            Text("12")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Feed Tab Integration

struct MainSocialFeedView: View {
    var body: some View {
        SocialFeedView()
    }
}

#Preview {
    SocialFeedView()
}
