import SwiftUI

@main
struct OHealthLiteApp: App {
    @StateObject private var store = HealthStore.shared
    @StateObject private var ble = WatchBLEManager.shared

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
