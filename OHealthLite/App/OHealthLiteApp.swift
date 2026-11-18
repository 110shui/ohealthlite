import SwiftUI

@main
struct OHealthLiteApp: App {
    @StateObject private var ble = WatchBLEManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ble)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var ble: WatchBLEManager
    @State private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("健康", systemImage: "heart.circle.fill") }
                .tag(0)
            ECGView()
                .tabItem { Label("心电", systemImage: "waveform.path.ecg") }
                .tag(1)
            DeviceView()
                .tabItem { Label("设备", systemImage: "applewatch") }
                .tag(2)
            LogView()
                .tabItem { Label("日志", systemImage: "doc.text.magnifyingglass") }
                .tag(3)
        }
        .tint(.red)
    }
}
