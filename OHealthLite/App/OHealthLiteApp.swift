import SwiftUI

@main
struct OHealthLiteApp: App {
    @StateObject private var store = HealthStore.shared
    @StateObject private var ble = WatchBLEManager.shared
    @StateObject private var bridge = WatchBridgeClient.shared

    init() {
        // 桥数据 → 健康中枢
        WatchBridgeClient.shared.onSample = { HealthStore.shared.applyBridgeSample($0) }
        // 手表端记录同步（RECORDS 响应）
        WatchBridgeClient.shared.onRecords = { HealthStore.shared.applyBridgeRecords($0) }
        // 手动测量结果（MEASURE 响应）
        WatchBridgeClient.shared.onMeasure = { HealthStore.shared.applyMeasureResult($0) }
        // 手表遥控命令 → 短视频翻页（系统音量键模拟）
        WatchBridgeClient.shared.onRemoteCommand = { RemoteControlManager.shared.handle($0) }
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
            .background(BridgeVolumeAttach())
        }
    }
}

/// 把隐藏的 MPVolumeView 挂到 window 层级（遥控音量模拟需要）
struct BridgeVolumeAttach: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        RemoteControlManager.shared.attach(to: v)
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
