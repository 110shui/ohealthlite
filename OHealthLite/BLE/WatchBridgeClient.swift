import Foundation
import Network

/// 手表数据桥客户端：WiFi 直连手表 9999 端口，接收 JSON 传感器数据。
/// {"hr":72,"steps":6421,"spo2Raw":818759,"hrAgeMs":1200,"clients":1,"ts":"..."}
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
        let hrAgeMs: Int?
        let clients: Int?
        let ts: String?
    }

    var onSample: ((Sample) -> Void)?

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

    private var buffer = Data()

    private func receive(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
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
                  let data = json.data(using: .utf8),
                  let sample = try? JSONDecoder().decode(Sample.self, from: data) else { continue }
            DispatchQueue.main.async {
                self.lastSeen = Date()
                self.lastPayload = json
                self.onSample?(sample)
            }
        }
    }
}
