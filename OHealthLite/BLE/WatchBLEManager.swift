import Foundation
import CoreBluetooth
import Combine

/// 手表蓝牙管理器：扫描、连接、GATT 枚举、notify 通道
///
/// 适配说明（刷机版小米 Watch 2 Pro LTE / OPPO 固件 monaco_go 17.MW2.1.0.1）：
/// - 手表作为 GATT Server 静态暴露 aa15 与 afaf 服务（实测 dumpsys bluetooth_manager）
/// - iOS 侧按 HeyAccessory SDK 约定应连接 bb15 服务组（动态注册，连接后可见）
/// - 手表广播在熄屏时不一定开启；扫描前请保持手表亮屏
final class WatchBLEManager: NSObject, ObservableObject {

    // MARK: - 发布状态
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var isScanning = false
    @Published var discovered: [DiscoveredWatch] = []
    @Published var connectedWatch: DiscoveredWatch?
    @Published var connectionPhase: ConnectionPhase = .idle
    @Published var services: [GATTServiceSnapshot] = []
    @Published var latestNotifyData: Data?
    @Published var log: [String] = []

    enum ConnectionPhase: String {
        case idle = "未连接"
        case connecting = "连接中…"
        case discovering = "发现服务中…"
        case ready = "已连接"
        case failed = "连接失败"
    }

    struct DiscoveredWatch: Identifiable, Equatable {
        let id: String          // peripheral.identifier.uuidString（iOS 用 UUID，不是 MAC）
        let name: String
        let rssi: Int
        let serviceUUIDs: [String]
        let manufacturerData: Data?
    }

    // MARK: - CoreBluetooth
    private var central: CBCentralManager!
    private var pendingPeripheral: CBPeripheral?
    private var connectedPeripheral: CBPeripheral?

    /// 当前数据通道（连接后确定：优先 bb15 组，其次 aa15 组）
    private(set) var notifyCharacteristic: CBCharacteristic?
    private(set) var writeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func appendLog(_ s: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        log.append("[\(fmt.string(from: Date()))] \(s)")
        if log.count > 300 { log.removeFirst(log.count - 300) }
    }

    // MARK: - 扫描
    func startScan() {
        guard central.state == .poweredOn else {
            appendLog("蓝牙未开启，无法扫描")
            return
        }
        discovered.removeAll()
        isScanning = true
        appendLog("开始扫描…（请保持手表亮屏）")
        // 先按服务 UUID 精确过滤；后台续扫用于兜底名称匹配
        central.scanForPeripherals(withServices: WatchProtocol.scanServices,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        // 3 秒后切换为全量扫描，兜底手表广播不带服务 UUID 的情况
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.isScanning else { return }
            self.appendLog("切换全量扫描（按名称/厂商数据过滤）")
            self.central.scanForPeripherals(withServices: nil,
                                            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        appendLog("扫描停止")
    }

    // MARK: - 连接
    func connect(_ target: DiscoveredWatch) {
        guard central.state == .poweredOn else { return }
        stopScan()
        connectionPhase = .connecting
        appendLog("连接 \(target.name.isEmpty ? target.id : target.name) …")
        if let p = central.retrievePeripherals(withIdentifiers: [UUID(uuidString: target.id)!]).first {
            pendingPeripheral = p
            central.connect(p, options: nil)
        }
    }

    func disconnect() {
        if let p = connectedPeripheral {
            central.cancelPeripheralConnection(p)
        }
    }

    /// 向手表写数据（走当前数据通道）
    func send(_ data: Data) {
        guard let p = connectedPeripheral, let ch = writeCharacteristic else {
            appendLog("⚠️ 未建立写通道")
            return
        }
        // BLE 默认 MTU 20 字节（iOS 可协商至 185+），此处按 20 分片，后续接帧协议时按协商 MTU 分片
        var offset = 0
        let chunk = 20
        while offset < data.count {
            let end = min(offset + chunk, data.count)
            p.writeValue(Data(data[offset..<end]), for: ch, type: ch.properties.contains(.write) ? .withResponse : .withoutResponse)
            offset = end
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension WatchBLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        switch central.state {
        case .poweredOn: appendLog("蓝牙已就绪")
        case .poweredOff: appendLog("蓝牙关闭")
        case .unauthorized: appendLog("蓝牙权限未授予（检查 Info.plist NSBluetoothAlwaysUsageDescription）")
        default: break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []
        let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? ""

        // 过滤规则：带已知服务 UUID，或名称含 OPPO/Watch/OWW，或厂商数据匹配 0x0006 0109
        var hit = !uuids.isEmpty && uuids.contains(where: { u in
            WatchProtocol.scanServices.map(\.uuidString).contains(u)
        })
        if !hit, name.lowercased().contains("oppo") || name.lowercased().contains("watch") { hit = true }
        if !hit, let m = mfg, m.count >= 4, m[0] == 0x01, m[1] == 0x09 { hit = true }
        if !hit { return }

        let item = DiscoveredWatch(id: peripheral.identifier.uuidString,
                                   name: name,
                                   rssi: RSSI.intValue,
                                   serviceUUIDs: uuids,
                                   manufacturerData: mfg)
        if let idx = discovered.firstIndex(where: { $0.id == item.id }) {
            discovered[idx] = item
        } else {
            discovered.append(item)
            appendLog("发现设备: \(name) rssi=\(RSSI.intValue) services=\(uuids)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appendLog("已建立链路，开始发现服务…")
        connectionPhase = .discovering
        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectedWatch = DiscoveredWatch(id: peripheral.identifier.uuidString,
                                         name: peripheral.name ?? "",
                                         rssi: 0, serviceUUIDs: [], manufacturerData: nil)
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?) {
        appendLog("连接失败: \(error?.localizedDescription ?? "unknown")")
        connectionPhase = .failed
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        appendLog("已断开\(error.map { ": " + $0.localizedDescription } ?? "")")
        connectionPhase = .idle
        connectedPeripheral = nil
        connectedWatch = nil
        notifyCharacteristic = nil
        writeCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate
extension WatchBLEManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error { appendLog("服务发现失败: \(e.localizedDescription)") }
        let found = peripheral.services ?? []
        appendLog("发现 \(found.count) 个服务: \(found.map { $0.uuid.uuidString.prefix(8) })")
        for s in found { peripheral.discoverCharacteristics(nil, for: s) }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let chars = service.characteristics ?? []
        appendLog("服务 \(service.uuid.uuidString.prefix(8)) 特征 \(chars.count) 个")

        // 依据 HeyAccessory SDK 约定选择数据通道
        // iOS 通道: bb16(notify) + bb17(write)；Android 通道: aa16 + aa17
        for ch in chars {
            let u = ch.uuid.uuidString
            if u == WatchProtocol.charReadSecondary || u == WatchProtocol.charReadPrimary {
                notifyCharacteristic = ch
                peripheral.setNotifyValue(true, for: ch)
                appendLog("✅ 订阅 notify 通道 \(u.prefix(8))")
            }
            if u == WatchProtocol.charWriteSecondary || u == WatchProtocol.charWritePrimary {
                writeCharacteristic = ch
                appendLog("✅ 绑定 write 通道 \(u.prefix(8))")
            }
        }
        refreshSnapshots(peripheral)

        // 全部特征就绪后进入 ready
        let total = peripheral.services?.reduce(0) { $0 + ($1.characteristics?.count ?? 0) } ?? 0
        let discoveredCount = peripheral.services?.count ?? 0
        if discoveredCount > 0 && total > 0 {
            // 粗略就绪判断：所有服务都有特征列表（nil error 情况下 characteristics 非空）
            if peripheral.services?.allSatisfy { $0.characteristics != nil } == true {
                connectionPhase = .ready
                appendLog("🎉 通道就绪")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error { appendLog("notify 错误: \(e.localizedDescription)"); return }
        latestNotifyData = characteristic.value
        refreshSnapshots(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error { appendLog("订阅失败: \(e.localizedDescription)") }
    }

    private func refreshSnapshots(_ peripheral: CBPeripheral) {
        services = (peripheral.services ?? []).map { svc in
            GATTServiceSnapshot(
                id: svc.uuid.uuidString,
                uuid: svc.uuid,
                characteristics: (svc.characteristics ?? []).map { ch in
                    var a: [String] = []
                    if ch.properties.contains(.read) { a.append("read") }
                    if ch.properties.contains(.write) { a.append("write") }
                    if ch.properties.contains(.writeWithoutResponse) { a.append("writeNR") }
                    if ch.properties.contains(.notify) { a.append("notify") }
                    if ch.properties.contains(.indicate) { a.append("indicate") }
                    return GATTCharacteristicSnapshot(
                        id: ch.uuid.uuidString,
                        uuid: ch.uuid,
                        properties: a,
                        value: ch.value)
                })
        }
    }
}
