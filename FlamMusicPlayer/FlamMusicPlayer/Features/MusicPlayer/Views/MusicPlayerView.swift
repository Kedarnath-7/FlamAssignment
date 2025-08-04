import SwiftUI

// MARK: - Main Music Player View
/// Complete music player interface combining all components
/// This is what users see when they tap the Music tab
struct MusicPlayerView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()
    @ObservedObject private var musicManager = MusicPlayerManager.shared
    @State private var showingQueue = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current song display
                    CurrentSongView(song: musicManager.currentSong)
                    
                    // Progress bar (only show if song is loaded)
                    if musicManager.currentSong != nil {
                        ProgressBarView(
                            musicManager: musicManager,
                            onSeek: viewModel.seekTo
                        )
                        .padding(.horizontal)
                    }
                    
                    // Player controls
                    PlayerControlsView(
                        musicManager: musicManager,
                        onTogglePlayPause: viewModel.togglePlayPause
                    )
                    
                    // Additional controls
                    additionalControlsView
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Song list section
                    songListSection
                }
                .padding()
            }
            .navigationTitle("Music Player")
            .searchable(text: $viewModel.searchText, prompt: "Search songs...")
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .sheet(isPresented: $showingQueue) {
                QueueView(musicManager: musicManager)
            }
        }
    }
    
    // MARK: - Additional Controls
    private var additionalControlsView: some View {
        VStack(spacing: 24) {
            // Playbook and queue controls
            HStack(spacing: 60) {
                // Shuffle button with enhanced styling
                Button(action: musicManager.togglePlaybackMode) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(musicManager.playbackMode == .normal ? Color(.systemGray6) : Color.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: musicManager.playbackMode.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(musicManager.playbackMode == .normal ? .secondary : .accentColor)
                        }
                        
                        Text(musicManager.playbackMode == .normal ? "Normal" : musicManager.playbackMode == .shuffle ? "Shuffle" : "Repeat")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Queue button with enhanced styling
                Button(action: { showingQueue = true }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "list.bullet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            if !musicManager.queue.isEmpty {
                                Text("\(musicManager.queue.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                    )
                                    .offset(x: 14, y: -14)
                            }
                        }
                        
                        Text("Queue")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Volume control with enhanced styling
            VStack(spacing: 10) {
                Text("Volume")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 14) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { Double(musicManager.volume) },
                        set: { musicManager.setVolume(Float($0)) }
                    ), in: 0...1)
                    .tint(.accentColor)
                    .frame(maxWidth: 160)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Song List Section
    private var songListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with improved styling
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("Songs")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.songs.count) songs available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            
                if viewModel.isLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Error message with better styling
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal)
            }
            
            // Songs list with full-width card container
            VStack(spacing: 0) {
                ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                    HStack(spacing: 0) {
                        SongRowView(
                            song: song,
                            isCurrentSong: song.id == musicManager.currentSong?.id,
                            onTap: {
                                viewModel.playAllSongs(startingFrom: index)
                            }
                        )
                        
                        // Add to queue button with enhanced styling
                        Button(action: {
                            musicManager.addToQueue(song)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.trailing, 20)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        // Full-width selection background
                        Rectangle()
                            .fill(song.id == musicManager.currentSong?.id ? Color.accentColor.opacity(0.1) : Color.clear)
                            .ignoresSafeArea(.container, edges: .horizontal)
                    )
                    
                    if index < viewModel.songs.count - 1 {
                        Divider()
                            .padding(.leading, 92) // Align with song title after larger artwork
                            .opacity(0.5)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 0)
        }
    }
}

// MARK: - Preview
#Preview {
    MusicPlayerView()
}
