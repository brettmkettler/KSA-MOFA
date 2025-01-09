import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }
            .tag(0)
            
            NavigationView {
                AboutView()
            }
            .tabItem {
                Image(systemName: "info.circle.fill")
                Text("About")
            }
            .tag(1)
        }
        .accentColor(.blue)
    }
}
