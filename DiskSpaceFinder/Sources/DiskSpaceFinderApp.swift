import SwiftUI

@main
struct DiskSpaceFinderApp: App {
    @StateObject private var scanManager = ScanManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
