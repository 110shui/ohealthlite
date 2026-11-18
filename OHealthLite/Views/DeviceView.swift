import SwiftUI
import CoreBluetooth

/// 设备 Tab —— 对齐官方「设备」页：设备卡 + 手表功能 + 蓝牙调试
struct DeviceView: View {
    @EnvironmentObject var ble: WatchBLEManager
    @EnvironmentObject var store: HealthStore
    @StateObject private var bridge = WatchBridgeClient.shared
    @AppStorage("bridgeHost") private var bridgeHost = "192.168.2.93"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    deviceHeroCard
                    bridgeCard
                    scanResult
                    featureList
                    debugEntry
                }
                .padding(16)
            }
            .background(Theme.pageBG)
            .navigationTitle("设备")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: 官方设备卡：产品图 + 设备名 + 状态 + 提示卡
    private var deviceHeroCard: some View {
        VStack(spacing: 14) {
            WatchProductImage(size: 220)
                .environmentObject(store)
            Text("OPPO Watch X3")
                .font(.oppo(24, weight: .bold))
            HStack(spacing: 6) {
                Circle()
                    .fill(bridge.isConnected || ble.connectedWatch != nil ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(bridge.isConnected ? "数据桥已连接，数据同步中" : (ble.connectedWatch != nil ? "蓝牙已连接" : "该设备当前无法使用"))
                    .font(.oppo(14, weight: .medium))
            }
            // 提示卡（官方样式：图标 + 标题 + 描述 + 主按钮 + 副操作）
            VStack(spacing: 14) {
                if bridge.isConnected {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.green)
                    Text("数据同步正常").font(.oppo(17, weight: .semibold))
                    Text("心率与步数将随官方 HealthKit 接入逐步点亮")
                        .font(.oppo(13)).foregroundColor(.secondary)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.red)
                    Text("手表未建立数据连接").font(.oppo(17, weight: .semibold))
                    Text("通过 WiFi 数据桥连接后即可同步健康数据")
                        .font(.oppo(13)).foregroundColor(.secondary)
                    Button {
                        bridge.connect(to: bridgeHost)
                    } label: {
                        Text("连接数据桥")
                            .font(.oppo(16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 40)
                    Text("连接前请确认手表已安装数据桥 APK")
                        .font(.oppo(14))
                        .foregroundColor(Color(hex: 0x2F6BF6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: 手表数据桥（WiFi 直连，绕过蓝牙认证）
    private var bridgeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(bridge.isConnected ? .green : Theme.accentCyan)
                    Text("手表数据桥（WiFi）").font(.oppo(15, weight: .semibold))
                    Spacer()
                    if bridge.isConnected {
                        Circle().fill(.green).frame(width: 8, height: 8)
                    }
                }
                HStack(spacing: 8) {
                    TextField("手表 IP（如 192.168.2.93）", text: $bridgeHost)
                        .keyboardType(.decimalPad)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(10)
                        .background(Color(hex: 0xF2F2F7))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(bridge.isConnected)
                    Button {
                        if bridge.isConnected {
                            bridge.disconnect()
                        } else {
                            bridge.connect(to: bridgeHost)
                        }
                    } label: {
                        Text(bridge.isConnected ? "断开" : "连接")
                            .font(.oppo(13, weight: .medium))
                            .frame(width: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(bridge.isConnected ? .red : Theme.accentCyan)
                }
                Text(bridge.stateText)
                    .font(.oppo(12)).foregroundColor(.secondary)
                if !bridge.lastPayload.isEmpty {
                    Text("最新数据：\(bridge.lastPayload)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Text("需手表端安装数据桥 APK 并与手机同 WiFi。桥为按需采样：连接时每 30 秒采一次，未连接每 5 分钟巡检一次。")
                    .font(.oppo(11)).foregroundColor(.secondary)
            }
        }
    }

    // MARK: 扫描结果
    @ViewBuilder private var scanResult: some View {
        if ble.isScanning || !ble.discoveredAll.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("显示全部蓝牙设备（刷机设备可能不匹配过滤规则）", isOn: $ble.showAllDevices)
                        .font(.oppo(12))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    let list = ble.showAllDevices ? ble.discoveredAll : ble.discovered
                    if list.isEmpty {
                        Text(ble.isScanning ? "扫描中… 保持手表亮屏" : "未发现设备，点上方\"扫描手表\"")
                            .font(.oppo(13)).foregroundColor(.secondary)
                    }
                    ForEach(list) { d in
                        Button {
                            ble.connect(d)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(d.name.isEmpty ? "(无名称)" : d.name)
                                            .font(.oppo(15)).foregroundColor(.primary)
                                        if isLikelyWatch(d) {
                                            Text("手表?")
                                                .font(.oppo(10, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Theme.accentCyan)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text("rssi \(d.rssi) · \(d.serviceUUIDs.isEmpty ? "无服务UUID" : d.serviceUUIDs.map { String($0.prefix(8)) }.joined(separator: ", "))")
                                        .font(.oppo(11)).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                        if d.id != list.last?.id { Divider() }
                    }
                }
            }
        }
    }

    /// 广播特征判断是否可能是手表（服务 UUID / 名称 / 厂商数据）
    private func isLikelyWatch(_ d: WatchBLEManager.DiscoveredWatch) -> Bool {
        let knownUUIDs = [WatchProtocol.servicePrimary, WatchProtocol.serviceSecondary,
                          WatchProtocol.serviceAFAF, WatchProtocol.serviceDiscovery,
                          WatchProtocol.serviceDiscoveryAlt]
        if d.serviceUUIDs.contains(where: { knownUUIDs.contains($0) }) { return true }
        let lower = d.name.lowercased()
        if lower.contains("oppo") || lower.contains("watch") || lower.contains("xiaomi") { return true }
        if let m = d.manufacturerData, m.count >= 2, m[0] == 0x06 || m[0] == 0x71 { return true }
        return false
    }

    // MARK: 手表功能开关（对齐官方设备功能列表）
    private var featureList: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                featureRow("heart.circle.fill", Theme.heartRed, "连续心率监测", "已开启")
                Divider().padding(.leading, 40)
                featureRow("lungs.fill", Theme.oxygenBlue, "睡眠血氧监测", "已开启")
                Divider().padding(.leading, 40)
                featureRow("bed.double.fill", Theme.sleepIndigo, "睡眠监测", "已开启")
                Divider().padding(.leading, 40)
                featureRow("bell.fill", Theme.stressOrange, "消息通知", "未开启")
                Divider().padding(.leading, 40)
                featureRow("camera.metering.unknown", Theme.accentPurple, "抬起唤醒", "已开启")
                Divider().padding(.leading, 40)
                featureRow("arrow.triangle.2.circlepath", Theme.accentCyan, "固件更新 (OTA)", "已是最新")
            }
        }
    }

    private func featureRow(_ icon: String, _ color: Color, _ name: String, _ state: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 28)
            Text(name).font(.oppo(15))
            Spacer()
            Text(state).font(.oppo(13)).foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var debugEntry: some View {
        NavigationLink {
            GATTDebugView()
        } label: {
            HStack {
                Image(systemName: "ant.fill").foregroundColor(.secondary)
                Text("GATT 服务调试").font(.oppo(14)).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
            }
            .padding(16)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// GATT 调试页（保留扫描/连接/服务快照能力）
struct GATTDebugView: View {
    @EnvironmentObject var ble: WatchBLEManager

    var body: some View {
        List {
            Section("状态") {
                LabeledRow("蓝牙", ble.bluetoothState.stateText)
                LabeledRow("阶段", ble.connectionPhase.rawValue)
            }
            Section("已发现设备") {
                if ble.discovered.isEmpty {
                    Button(ble.isScanning ? "扫描中…" : "开始扫描") {
                        ble.isScanning ? ble.stopScan() : ble.startScan()
                    }
                }
                ForEach(ble.discovered) { d in
                    Button(d.name.isEmpty ? d.id : d.name) { ble.connect(d) }
                }
            }
            Section("GATT 服务快照") {
                if ble.services.isEmpty {
                    Text("未发现服务").foregroundColor(.secondary)
                }
                ForEach(ble.services) { svc in
                    DisclosureGroup {
                        ForEach(svc.characteristics) { ch in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ch.uuid.uuidString).font(.footnote.monospaced())
                                Text(ch.properties.joined(separator: " / "))
                                    .font(.caption2).foregroundStyle(.secondary)
                                if let v = ch.value {
                                    Text("value: \(v.map { String(format: "%02x", $0) }.joined())")
                                        .font(.caption2.monospaced()).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            let known = describeService(svc.uuid.uuidString)
                            Text(known.name).font(.subheadline)
                            Spacer()
                            Text(known.role).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("日志") {
                ForEach(Array(ble.log.suffix(60).enumerated().reversed()), id: \.offset) { _, line in
                    Text(line).font(.system(.caption2, design: .monospaced))
                }
            }
        }
        .navigationTitle("GATT 调试")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func describeService(_ uuid: String) -> (name: String, role: String) {
        switch uuid {
        case WatchProtocol.servicePrimary:
            return ("AFAF 数据服务 (aa15)", "Android 通道 · notify aa16 / write aa17")
        case WatchProtocol.serviceSecondary:
            return ("BB15 数据服务 (bb15)", "iOS 通道 · notify bb16 / write bb17")
        case WatchProtocol.serviceAFAF:
            return ("AF 服务 (afaf)", "系统服务 · 特征 0001/1001/1004")
        case WatchProtocol.serviceDiscovery:
            return ("发现服务 (a49eaa15)", "SDK 扫描/经典蓝牙 RFCOMM")
        case WatchProtocol.serviceDiscoveryAlt:
            return ("发现服务 B (a49ebb15)", "SDK 扫描")
        default:
            return (uuid, "")
        }
    }
}

struct LabeledRow: View {
    let k: String
    let v: String
    init(_ k: String, _ v: String) { self.k = k; self.v = v }
    var body: some View {
        HStack { Text(k); Spacer(); Text(v).foregroundColor(.secondary) }
    }
}

/// 调试日志页
struct LogView: View {
    @EnvironmentObject var ble: WatchBLEManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if ble.log.isEmpty {
                        Text("暂无日志").foregroundStyle(.secondary)
                    }
                    ForEach(Array(ble.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption.monospaced())
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: ble.log.count) { _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        .navigationTitle("BLE 日志")
    }
}

extension CBManagerState {
    var stateText: String {
        switch self {
        case .poweredOn: return "已开启"
        case .poweredOff: return "已关闭"
        case .unauthorized: return "未授权"
        case .resetting: return "重置中"
        case .unsupported: return "不支持"
        default: return "未知"
        }
    }
}
