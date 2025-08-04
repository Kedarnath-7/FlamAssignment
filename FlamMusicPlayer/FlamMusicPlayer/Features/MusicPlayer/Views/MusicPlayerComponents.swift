import SwiftUI

// MARK: - Song Row Component
/// Displays individual song information in a list
/// Reusable component that can be used anywhere
struct SongRowView: View {
    let song: Song
    let isCurrentSong: Bool
    let onTap: () -> Void
    
    private var sourceColor: Color {
        switch song.source {
        case .local: return .blue
        case .spotify: return .green
        case .appleMusic: return .pink
        }
    }
    
    private var sourceDisplayName: String {
        switch song.source {
        case .local: return "LOCAL"
        case .spotify: return "SPOTIFY"
        case .appleMusic: return "APPLE"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Song artwork placeholder with enhanced styling
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            sourceColor.opacity(0.9),
                            sourceColor.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .shadow(color: sourceColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: song.source.iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                )
            
            // Song info with improved typography
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrentSong ? .accentColor : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(song.artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Compact source indicator
                    Text(sourceDisplayName)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(sourceColor.opacity(0.15))
                        )
                        .foregroundColor(sourceColor)
                }
                
                if let album = song.album {
                    Text(album)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
            
            // Duration and playing indicator
            VStack(alignment: .trailing, spacing: 6) {
                Text(Date.formatDuration(song.duration))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                // Playing indicator with animation
                if isCurrentSong {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isCurrentSong)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Player Controls Component
/// Main playback controls (play, pause, next, previous)
/// Central component for music control
struct PlayerControlsView: View {
    @ObservedObject var musicManager: MusicPlayerManager
    let onTogglePlayPause: () -> Void
    
    var body: some View {
        HStack(spacing: 50) {
            // Previous button with enhanced styling
            Button(action: musicManager.playPrevious) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .opacity(musicManager.queue.isEmpty ? 0.6 : 1.0)
                    
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(musicManager.queue.isEmpty ? .secondary : .primary)
                }
                .scaleEffect(musicManager.queue.isEmpty ? 0.95 : 1.0)
            }
            .disabled(musicManager.queue.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: musicManager.queue.isEmpty)
            .buttonStyle(PlainButtonStyle())
            
            // Main play/pause button with enhanced styling
            Button(action: onTogglePlayPause) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    musicManager.currentSong == nil ? Color.gray : Color.accentColor,
                                    musicManager.currentSong == nil ? Color.gray.opacity(0.8) : Color.accentColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: musicManager.playerState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: musicManager.playerState.isPlaying ? 0 : 2) // Slight offset for play icon
                }
                .scaleEffect(musicManager.currentSong == nil ? 0.95 : 1.0)
            }
            .disabled(musicManager.currentSong == nil)
            .animation(.easeInOut(duration: 0.2), value: musicManager.currentSong)
            .animation(.easeInOut(duration: 0.15), value: musicManager.playerState.isPlaying)
            .buttonStyle(PlainButtonStyle())
            
            // Next button with enhanced styling
            Button(action: musicManager.playNext) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .opacity(musicManager.queue.isEmpty ? 0.6 : 1.0)
                    
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(musicManager.queue.isEmpty ? .secondary : .primary)
                }
                .scaleEffect(musicManager.queue.isEmpty ? 0.95 : 1.0)
            }
            .disabled(musicManager.queue.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: musicManager.queue.isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Progress Bar Component
/// Shows current playback progress and allows seeking
/// Interactive component for time navigation
struct ProgressBarView: View {
    @ObservedObject var musicManager: MusicPlayerManager
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var progress: Double {
        guard musicManager.duration > 0 else { return 0 }
        return isDragging ? dragValue : musicManager.currentTime / musicManager.duration
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress slider with enhanced styling
            VStack(spacing: 8) {
                // Custom progress track
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        // Progress track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                            .offset(x: geometry.size.width * progress - (isDragging ? 8 : 6))
                            .animation(.easeInOut(duration: 0.1), value: isDragging)
                    }
                }
                .frame(height: 20)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newProgress = max(0, min(1, value.location.x / UIScreen.main.bounds.width * 0.8))
                            dragValue = newProgress
                        }
                        .onEnded { value in
                            isDragging = false
                            let newProgress = max(0, min(1, value.location.x / UIScreen.main.bounds.width * 0.8))
                            onSeek(newProgress)
                        }
                )
            }
            
            // Time labels with improved styling
            HStack {
                Text(Date.formatDuration(isDragging ? dragValue * musicManager.duration : musicManager.currentTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(Date.formatDuration(musicManager.duration))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Current Song Display
/// Shows currently playing song information
/// Header component for the player
struct CurrentSongView: View {
    let song: Song?
    
    var body: some View {
        VStack(spacing: 16) {
            if let song = song {
                // Large artwork placeholder with enhanced styling
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                song.source == .local ? Color.blue : 
                                song.source == .spotify ? Color.green : Color.pink,
                                song.source == .local ? Color.blue.opacity(0.6) : 
                                song.source == .spotify ? Color.green.opacity(0.6) : Color.pink.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: song.source.iconName)
                                .font(.system(size: 70, weight: .light))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                            
                            Text(song.source.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    )
                
                // Song details with improved typography
                VStack(spacing: 6) {
                    Text(song.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(song.artist)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    if let album = song.album {
                        Text(album)
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // No song selected state with enhanced styling
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 4) {
                                Text("No Song Selected")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                
                                Text("Choose a song to start playing")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    )
            }
        }
    }
}
