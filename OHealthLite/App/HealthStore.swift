import Foundation
import Combine

/// 健康数据中枢。
/// 数据源：手表数据桥（WiFi TCP 9999，桥 APK 按需采样推送 JSON）；
/// 蓝牙通道（WatchBLEManager）保留为后续 OLink 协议逆向的接入点。
final class HealthStore: ObservableObject {
    static let shared = HealthStore()

    // MARK: - 今日指标
    @Published var steps: Int = 0
    @Published var stepGoal: Int = 8000
    @Published var calories: Int = 0
    @Published var exerciseMinutes: Int = 0
    @Published var workouts: Int = 0
    @Published var calorieGoal: Int = 300
    @Published var exerciseGoal: Int = 30
    @Published var workoutsGoal: Int = 12

    @Published var heartRate: Int = 0
    @Published var restingHeartRate: Int = 0
    @Published var bloodOxygen: Int = 0
    @Published var stressScore: Int = 0
    @Published var hrv: Double = 0
    @Published var skinTempDelta: Double = 0
    @Published var systolic: Int = 0
    @Published var diastolic: Int = 0
    @Published var bloodSugar: Double = 0
    /// 手表佩戴状态（桥 type 34 传感器），nil=未知
    @Published var watchWorn: Bool?

    // 睡眠
    @Published var sleepMinutes: Int = 0
    @Published var deepMinutes: Int = 0
    @Published var lightMinutes: Int = 0
    @Published var remMinutes: Int = 0
    @Published var awakeMinutes: Int = 0

    // 心率历史（最近 N 小时，用于详情图）
    @Published var heartRateSamples: [Sample] = []
    @Published var bloodOxygenSamples: [Sample] = []
    @Published var stressSamples: [Sample] = []

    // 心电
    @Published var ecgRecords: [ECGRecord] = []

    // 运动记录
    @Published var sportRecords: [SportRecord] = []

    // 血压记录（手动录入 + 手表同步）
    @Published var bpRecords: [BPRecord] = [] {
        didSet { persistBP() }
    }

    struct BPRecord: Identifiable, Codable {
        let id: String
        let date: Date
        let systolic: Int
        let diastolic: Int
    }

    // 测定状态（心率/血氧手动测量）
    @Published var measuring = false
    @Published var lastMeasureResult = ""

    struct Sample: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    struct ECGRecord: Identifiable {
        let id = UUID()
        let date: Date
        let result: String   // 窦性心律 / 异常 等
        let bpm: Int
        let durationSeconds: Int
    }

    struct SportRecord: Identifiable {
        let id = UUID()
        let date: Date
        let type: String     // 户外跑步 / 户外骑行 / 健身
        let distanceKm: Double
        let durationMinutes: Int
        let calories: Int
        let avgHeartRate: Int
    }

    init() {
        seedDemoData()
        loadBP()
    }

    /// 默认空数据（未连接手表，与官方 App 空态一致）；阶段2由手表同步填充
    private func seedDemoData() {
        let now = Date()
        let calendar = Calendar.current
        _ = now; _ = calendar
    }

    var sleepTotalHours: Double { Double(sleepMinutes) / 60 }
    var stepProgress: Double { Double(steps) / Double(max(stepGoal, 1)) }
    var exerciseProgress: Double { Double(exerciseMinutes) / Double(max(exerciseGoal, 1)) }
    var calorieProgress: Double { Double(calories) / Double(max(calorieGoal, 1)) }
    var workoutsProgress: Double { Double(workouts) / Double(max(workoutsGoal, 1)) }

    // MARK: - 桥数据接入
    /// 由 WatchBridgeClient 推送的真实手表数据
    func applyBridgeSample(_ s: WatchBridgeClient.Sample) {
        let changedHR = s.hr > 0
        if changedHR {
            heartRate = s.hr
            restingHeartRate = restingHeartRate == 0 ? s.hr : min(restingHeartRate, s.hr)
            heartRateSamples.append(Sample(date: Date(), value: Double(s.hr)))
            if heartRateSamples.count > 288 { heartRateSamples.removeFirst(heartRateSamples.count - 288) }
        }
        if s.steps > 0 {
            steps = max(steps, s.steps)
            calories = max(calories, steps / 25)   // 粗略换算，后续由手表侧健康服务提供
        }
        if let pct = s.spo2, pct > 0 {
            // 桥端合成的血氧百分比（0-100）
            bloodOxygen = pct
            bloodOxygenSamples.append(Sample(date: Date(), value: Double(pct)))
            if bloodOxygenSamples.count > 96 { bloodOxygenSamples.removeFirst(bloodOxygenSamples.count - 96) }
        }
        if let worn = s.worn {
            watchWorn = worn == 1
        }
    }

    // MARK: - 手表端记录同步
    /// 桥返回的手表记录（RECORDS 响应）：hr/spo2 为 [[tsMs, 值x10]]
    func applyBridgeRecords(_ r: WatchBridgeClient.RecordsPayload) {
        let calendar = Calendar.current
        if let hrList = r.hr, !hrList.isEmpty {
            // 记录即权威数据源：直接重建 24h 内样本
            var samples: [Sample] = []
            for pair in hrList where pair.count >= 2 {
                let d = Date(timeIntervalSince1970: Double(pair[0]) / 1000)
                if let days = calendar.dateComponents([.day], from: d, to: Date()).day, days <= 2 {
                    samples.append(Sample(date: d, value: Double(pair[1]) / 10))
                }
            }
            heartRateSamples = samples.sorted { $0.date < $1.date }
            if let last = heartRateSamples.last, heartRate == 0 { heartRate = Int(last.value) }
        }
        if let spo2List = r.spo2, !spo2List.isEmpty {
            var samples: [Sample] = []
            for pair in spo2List where pair.count >= 2 {
                let d = Date(timeIntervalSince1970: Double(pair[0]) / 1000)
                if let days = calendar.dateComponents([.day], from: d, to: Date()).day, days <= 2 {
                    samples.append(Sample(date: d, value: Double(pair[1]) / 10))
                }
            }
            bloodOxygenSamples = samples.sorted { $0.date < $1.date }
            if let last = bloodOxygenSamples.last, bloodOxygen == 0 { bloodOxygen = Int(last.value) }
        }
    }

    /// 手动测量结果（MEASURE 响应）
    func applyMeasureResult(_ m: WatchBridgeClient.MeasureResult) {
        measuring = false
        var parts: [String] = []
        if let hr = m.hr, hr > 0 {
            heartRate = hr
            heartRateSamples.append(Sample(date: Date(), value: Double(hr)))
            parts.append("心率 \(hr) 次/分")
        } else {
            parts.append("心率未测出")
        }
        if let spo2 = m.spo2, spo2 > 0 {
            bloodOxygen = spo2
            bloodOxygenSamples.append(Sample(date: Date(), value: Double(spo2)))
            parts.append("血氧 \(spo2)%")
        }
        lastMeasureResult = parts.joined(separator: " · ")
    }

    // MARK: - 血压记录
    func addBP(systolic sys: Int, diastolic dia: Int) {
        guard sys > 50, sys < 260, dia > 30, dia < 200 else { return }
        let rec = BPRecord(id: UUID().uuidString, date: Date(), systolic: sys, diastolic: dia)
        bpRecords.append(rec)
        if bpRecords.count > 200 { bpRecords.removeFirst(bpRecords.count - 200) }
        self.systolic = sys
        self.diastolic = dia
    }

    private func persistBP() {
        if let data = try? JSONEncoder().encode(bpRecords) {
            UserDefaults.standard.set(data, forKey: "ohealth.bp.records")
        }
    }

    private func loadBP() {
        if let data = UserDefaults.standard.data(forKey: "ohealth.bp.records"),
           let list = try? JSONDecoder().decode([BPRecord].self, from: data), !list.isEmpty {
            bpRecords = list
            if let last = list.last {
                systolic = last.systolic
                diastolic = last.diastolic
            }
        }
    }
}
