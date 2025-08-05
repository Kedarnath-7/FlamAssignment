import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Challenge 1: Music Player
            MusicPlayerView()
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Music")
                }
                .tag(0)
            
            // Challenge 3: Social Feed
            MainSocialFeedView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Feed")
                }
                .tag(1)
        }
        .onAppear {
            setupDependencies()
        }
    }
    
    private func setupDependencies() {
        // Register music sources
        DIContainer.shared.register(LocalMusicSource.self) { LocalMusicSource() }
        DIContainer.shared.register(SpotifyMusicSource.self) { SpotifyMusicSource() }
        DIContainer.shared.register(AppleMusicSource.self) { AppleMusicSource() }
        
        // Register social feed services
        DIContainer.shared.register(SocialFeedServiceProtocol.self) { MockSocialFeedService() }
    }
}

#Preview {
    ContentView()
}