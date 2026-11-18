import SwiftUI

/// 设备页：扫描 / 连接 / GATT 详情
struct DeviceView: View {
    @EnvironmentObject var ble: WatchBLEManager

    var body: some View {
        NavigationStack {
        List {
            Section("连接状态") {
                if let w = ble.connectedWatch {
                    HStack {
                        Image(systemName: "applewatch").foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text(w.name.isEmpty ? "OPPO Watch" : w.name)
                            Text(ble.connectionPhase.rawValue)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("断开") { ble.disconnect() }
                            .buttonStyle(.bordered)
                            .tint(.red)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("未连接").foregroundStyle(.secondary)
                        Button {
                            ble.isScanning ? ble.stopScan() : ble.startScan()
                        } label: {
                            Label(ble.isScanning ? "停止扫描" : "扫描手表",
                                  systemImage: ble.isScanning ? "stop.circle" : "dot.radiowaves.left.and.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(ble.bluetoothState != .poweredOn)
                        if ble.bluetoothState != .poweredOn {
                            Text("提示：请在系统设置授权蓝牙，并保持手表亮屏")
                                .font(.caption2).foregroundStyle(.orange)
                        }
                    }
                }
            }

            if ble.isScanning || !ble.discovered.isEmpty {
                Section("发现的设备") {
                    ForEach(ble.discovered) { d in
                        Button { ble.connect(d) } label: {
                            HStack {
                                Image(systemName: "applewatch")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading) {
                                    Text(d.name.isEmpty ? "(未命名设备)" : d.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("rssi \(d.rssi) · \(d.serviceUUIDs.map { String($0.prefix(8)) }.joined(separator: ", "))")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            if !ble.services.isEmpty {
                Section("GATT 服务（实测快照）") {
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
                                .padding(.vertical, 2)
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
            }
        }
        .navigationTitle("设备")
        }
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

/// 调试日志页
struct LogView: View {
    @EnvironmentObject var ble: WatchBLEManager

    var body: some View {
        NavigationStack {
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
}
