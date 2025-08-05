import SwiftUI
import Combine

// MARK: - Feed Item Components

struct FeedItemView: View {
    let post: Post
    let onLike: () -> Void
    let onRepost: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post header
            PostHeaderView(post: post)
            
            // Post content
            PostContentView(post: post)
            
            // Post media/attachments
            if !post.media.isEmpty {
                PostMediaView(media: post.media)
            }
            
            // Poll if present
            if let poll = post.poll {
                PostPollView(poll: poll)
            }
            
            // Engagement metrics
            PostEngagementView(post: post)
            
            // Action buttons
            PostActionsView(
                post: post,
                onLike: onLike,
                onRepost: onRepost,
                onBookmark: onBookmark,
                onShare: onShare
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Post Header

struct PostHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: post.user.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(post.user.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if post.user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("@\(post.user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // More options button
            Button(action: {
                // Show more options
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
    }
}

// MARK: - Post Content

struct PostContentView: View {
    let post: Post
    
    var body: some View {
        if !post.content.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(post.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 8)
                
                // Hashtags and mentions
                if !post.hashtags.isEmpty || !post.mentions.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 4) {
                        ForEach(post.hashtags, id: \.self) { hashtag in
                            Text("#\(hashtag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                        
                        ForEach(post.mentions, id: \.self) { mention in
                            Text("@\(mention)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Post Media

struct PostMediaView: View {
    let media: [PostMedia]
    
    var body: some View {
        if let firstMedia = media.first {
            switch firstMedia.type {
            case .image:
                ImageMediaView(media: firstMedia)
            case .video:
                VideoMediaView(media: firstMedia)
            case .gif:
                GifMediaView(media: firstMedia)
            }
        }
    }
}

struct ImageMediaView: View {
    let media: PostMedia
    
    var body: some View {
        AsyncImage(url: URL(string: media.url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    ProgressView()
                )
        }
        .frame(maxHeight: 300)
        .clipped()
        .cornerRadius(12)
        .padding(.vertical, 8)
    }
}

struct VideoMediaView: View {
    let media: PostMedia
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: media.thumbnailURL ?? media.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(maxHeight: 225)
            .clipped()
            .cornerRadius(12)
            
            // Play button overlay
            Button(action: {
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Duration badge
            if let duration = media.duration {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GifMediaView: View {
    let media: PostMedia
    
    var body: some View {
        AsyncImage(url: URL(string: media.url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    ProgressView()
                )
        }
        .frame(maxHeight: 250)
        .clipped()
        .cornerRadius(12)
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Text("GIF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(8)
                }
                Spacer()
            }
        )
        .padding(.vertical, 8)
    }
}

// MARK: - Post Poll

struct PostPollView: View {
    let poll: Poll
    @State private var selectedOption: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.headline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                ForEach(poll.options) { option in
                    PollOptionView(
                        option: option,
                        totalVotes: poll.totalVotes,
                        isSelected: selectedOption == option.id,
                        userHasVoted: poll.userVote != nil,
                        onTap: {
                            if poll.userVote == nil && !poll.isExpired {
                                selectedOption = option.id
                            }
                        }
                    )
                }
            }
            
            HStack {
                Text("\(poll.totalVotes) votes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let endsAt = poll.endsAt {
                    Text(poll.isExpired ? "Ended" : "Ends \(endsAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.vertical, 8)
    }
}

struct PollOptionView: View {
    let option: PollOption
    let totalVotes: Int
    let isSelected: Bool
    let userHasVoted: Bool
    let onTap: () -> Void
    
    private var percentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.voteCount) / Double(totalVotes)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if userHasVoted {
                    Text("\(Int(percentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    
                    if userHasVoted {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: UIScreen.main.bounds.width * percentage * 0.8)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(userHasVoted)
    }
}

// MARK: - Engagement Metrics

struct PostEngagementView: View {
    let post: Post
    
    var body: some View {
        if hasEngagement {
            HStack(spacing: 16) {
                if post.likeCount > 0 {
                    Text("\(post.formattedLikeCount) likes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if post.repostCount > 0 {
                    Text("\(post.formattedRepostCount) reposts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if post.replyCount > 0 {
                    Text("\(post.formattedReplyCount) replies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var hasEngagement: Bool {
        post.likeCount > 0 || post.repostCount > 0 || post.replyCount > 0
    }
}

// MARK: - Post Actions

struct PostActionsView: View {
    let post: Post
    let onLike: () -> Void
    let onRepost: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Like button
            ActionButton(
                icon: post.isLiked ? "heart.fill" : "heart",
                color: post.isLiked ? .red : .secondary,
                count: post.likeCount,
                action: onLike
            )
            
            Spacer()
            
            // Reply button
            ActionButton(
                icon: "bubble.left",
                color: .secondary,
                count: post.replyCount,
                action: {
                    // Handle reply
                }
            )
            
            Spacer()
            
            // Repost button
            ActionButton(
                icon: post.isReposted ? "arrow.2.squarepath" : "arrow.2.squarepath",
                color: post.isReposted ? .green : .secondary,
                count: post.repostCount,
                action: onRepost
            )
            
            Spacer()
            
            // Bookmark button
            ActionButton(
                icon: post.isBookmarked ? "bookmark.fill" : "bookmark",
                color: post.isBookmarked ? .blue : .secondary,
                action: onBookmark
            )
            
            Spacer()
            
            // Share button
            ActionButton(
                icon: "square.and.arrow.up",
                color: .secondary,
                action: onShare
            )
        }
        .padding(.vertical, 8)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    var count: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                if count > 0 {
                    Text(formatCount(count))
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Loading States

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading posts...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LoadMoreView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading more...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No posts yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Pull to refresh or check your connection")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
