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
        if let raw = s.spo2Raw, raw > 0, raw < 100000 {
            // 合成的 spo2 值（0-100）才采用；>100000 是未佩戴的 PPG 噪声
            bloodOxygen = raw
            bloodOxygenSamples.append(Sample(date: Date(), value: Double(raw)))
            if bloodOxygenSamples.count > 96 { bloodOxygenSamples.removeFirst(bloodOxygenSamples.count - 96) }
        }
        if let worn = s.worn {
            watchWorn = worn == 1
        }
    }
}
