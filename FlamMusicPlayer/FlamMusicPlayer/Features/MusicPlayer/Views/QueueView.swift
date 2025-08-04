import SwiftUI

// MARK: - Queue Management View
/// Displays and manages the current playback queue
/// Shows what's currently playing and what's coming up next
struct QueueView: View {
    @ObservedObject var musicManager: MusicPlayerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current playing section
                if let currentSong = musicManager.currentSong {
                    currentlyPlayingSection(currentSong)
                }
                
                Divider()
                
                // Queue section
                queueSection
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Queue") {
                            musicManager.clearQueue()
                        }
                        
                        Button("Shuffle Queue") {
                            musicManager.shuffleQueue()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Currently Playing Section
    private func currentlyPlayingSection(_ song: Song) -> some View {
        VStack(spacing: 12) {
            Text("Now Playing")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Song artwork
                RoundedRectangle(cornerRadius: 8)
                    .fill(song.source == .local ? Color.blue.opacity(0.2) : 
                          song.source == .spotify ? Color.green.opacity(0.2) : 
                          Color.pink.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: song.source.iconName)
                            .font(.title2)
                            .foregroundColor(song.source == .local ? .blue : 
                                           song.source == .spotify ? .green : .pink)
                    )
                
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Playing indicator
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Queue Section
    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Up Next")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                if !musicManager.queue.isEmpty {
                    Text("\(musicManager.queue.count) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            
            if musicManager.queue.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No songs in queue")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Add songs to see them here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Queue list
                List {
                    ForEach(Array(musicManager.queue.enumerated()), id: \.element.id) { index, song in
                        QueueRowView(
                            song: song,
                            position: index + 1,
                            isCurrent: index == musicManager.currentIndex,
                            onRemove: {
                                musicManager.removeFromQueue(at: index)
                            },
                            onPlay: {
                                musicManager.currentIndex = index
                                musicManager.play(song: song)
                            }
                        )
                    }
                    .onMove { source, destination in
                        if let sourceIndex = source.first {
                            musicManager.reorderInQueue(from: sourceIndex, to: destination)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// MARK: - Queue Row View
struct QueueRowView: View {
    let song: Song
    let position: Int
    let isCurrent: Bool
    let onRemove: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Song artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(song.source == .local ? Color.blue.opacity(0.2) : 
                      song.source == .spotify ? Color.green.opacity(0.2) : 
                      Color.pink.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: song.source.iconName)
                        .font(.caption)
                        .foregroundColor(song.source == .local ? .blue : 
                                       song.source == .spotify ? .green : .pink)
                )
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isCurrent ? .accentColor : .primary)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(Date.formatDuration(song.duration))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Actions menu
            Menu {
                Button("Play Now") {
                    onPlay()
                }
                
                Button("Remove from Queue", role: .destructive) {
                    onRemove()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay()
        }
    }
}

// MARK: - Preview
#Preview {
    QueueView(musicManager: MusicPlayerManager.shared)
}
