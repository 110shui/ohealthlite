import Foundation
import Network

/// 手表数据桥客户端：WiFi 直连手表 9999 端口，双向 JSON 协议。
/// 接收：{"hr":72,"steps":6421,"spo2Raw":818759,"spo2":97,"worn":1,...}（3 秒推送）
///       {"type":"records","hr":[[ts,v10]],"spo2":[[ts,v10]]}（记录同步）
///       {"type":"measure","hr":..,"spo2":..}（手动测量结果）
///       {"cmd":"VOLUP"}（手表遥控命令）
/// 发送：RECORDS / MEASURE / CONFIG hrInterval=N spo2Interval=M
final class WatchBridgeClient: ObservableObject {
    static let shared = WatchBridgeClient()

    @Published var stateText = "未连接"
    @Published var isConnected = false
    @Published var lastSeen: Date?
    @Published var lastPayload: String = ""

    private var connection: NWConnection?
    private var host: String = ""
    private let queue = DispatchQueue(label: "bridge.client")

    struct Sample: Codable {
        let hr: Int
        let steps: Int
        let spo2Raw: Int?
        let spo2: Int?
        let worn: Int?
        let hrAgeMs: Int?
        let clients: Int?
        let ts: String?
    }

    struct MeasureResult: Codable {
        let type: String
        let hr: Int?
        let spo2: Int?
        let worn: Int?
        let ts: Int64?
    }

    struct RecordsPayload: Codable {
        let type: String
        let hr: [[Int64]]?
        let spo2: [[Int64]]?
    }

    struct RemoteCommand: Codable {
        let cmd: String
    }

    var onSample: ((Sample) -> Void)?
    var onMeasure: ((MeasureResult) -> Void)?
    var onRecords: ((RecordsPayload) -> Void)?
    var onRemoteCommand: ((String) -> Void)?

    func connect(to host: String) {
        self.host = host
        disconnect()
        stateText = "连接中…"
        let conn = NWConnection(host: NWEndpoint.Host(host),
                                port: NWEndpoint.Port(integerLiteral: 9999),
                                using: .tcp)
        connection = conn
        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                guard let self else { return }
                switch state {
                case .ready:
                    self.isConnected = true
                    self.stateText = "已连接 \(self.host):9999"
                    // 连接后立即同步手表端记录
                    self.send("RECORDS")
                case .failed(let e):
                    self.isConnected = false
                    self.stateText = "连接失败：\(e.localizedDescription)"
                case .cancelled:
                    self.isConnected = false
                    self.stateText = "已断开"
                default: break
                }
            }
        }
        conn.start(queue: queue)
        receive(on: conn)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    /// 发送命令行（RECORDS / MEASURE / CONFIG ...）
    func send(_ text: String) {
        guard let conn = connection, conn.state == .ready else { return }
        let payload = (text + "\n").data(using: .utf8) ?? Data()
        conn.send(content: payload, completion: .contentProcessed { _ in })
    }

    /// 请求手表立即测量一次心率/血氧
    func requestMeasure() {
        send("MEASURE")
    }

    /// 下发测定设置
    func sendConfig(hrInterval: Int, spo2Interval: Int) {
        send("CONFIG hrInterval=\(hrInterval) spo2Interval=\(spo2Interval)")
    }

    private var buffer = Data()

    private func receive(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.buffer.append(data)
                self.parseBuffer()
            }
            if error == nil && !isComplete {
                self.receive(on: conn)
            }
        }
    }

    private func parseBuffer() {
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            guard let json = String(data: Data(line), encoding: .utf8),
                  let data = json.data(using: .utf8) else { continue }
            DispatchQueue.main.async {
                self.lastSeen = Date()
                self.lastPayload = json
                // 分发：状态样本 / 命令 / 测量结果 / 记录同步
                if let sample = try? JSONDecoder().decode(Sample.self, from: data) {
                    self.onSample?(sample)
                    return
                }
                if let cmd = try? JSONDecoder().decode(RemoteCommand.self, from: data) {
                    self.onRemoteCommand?(cmd.cmd)
                    return
                }
                if let m = try? JSONDecoder().decode(MeasureResult.self, from: data) {
                    self.onMeasure?(m)
                    return
                }
                if let r = try? JSONDecoder().decode(RecordsPayload.self, from: data) {
                    self.onRecords?(r)
                    return
                }
            }
        }
    }
}
