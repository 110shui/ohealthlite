import SwiftUI

@main
struct OHealthLiteApp: App {
    @StateObject private var store = HealthStore.shared
    @StateObject private var ble = WatchBLEManager.shared
    @StateObject private var bridge = WatchBridgeClient.shared

    init() {
        // 桥数据 → 健康中枢
        WatchBridgeClient.shared.onSample = { HealthStore.shared.applyBridgeSample($0) }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label("健康", systemImage: "heart.fill") }
                SportView()
                    .tabItem { Label("运动", systemImage: "shoe") }
                DeviceView()
                    .tabItem { Label("设备", systemImage: "applewatch") }
                MeView()
                    .tabItem { Label("我的", systemImage: "person.crop.circle") }
            }
            .tint(.primary)
            .environmentObject(store)
            .environmentObject(ble)
        }
    }
}
