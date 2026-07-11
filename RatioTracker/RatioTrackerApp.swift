import SwiftUI

@main
struct RatioTrackerApp: App {
    #if os(macOS)
    var body: some Scene {
        MenuBarExtra {
            StandaloneMenuBarView()
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
        }
        .menuBarExtraStyle(.window)

        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
    #else
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
    #endif
}

#if os(macOS)
struct StandaloneMenuBarView: View {
    @StateObject private var viewModel = RatioViewModel()
    @State private var timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        MenuBarContentView()
            .environmentObject(viewModel)
            .onReceive(timer) { _ in
                Task { await viewModel.refresh() }
            }
    }
}
#endif
