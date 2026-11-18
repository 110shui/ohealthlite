import Foundation
import Combine

/// 健康数据中枢。
/// 阶段1：本地模拟数据（对齐官方指标口径）。
/// 阶段2：接入手表 BLE 协议后由 WatchBLEManager 填充真实数据。
final class HealthStore: ObservableObject {
    static let shared = HealthStore()

    // MARK: - 今日指标
    @Published var steps: Int = 0
    @Published var stepGoal: Int = 8000
    @Published var calories: Int = 0
    @Published var exerciseMinutes: Int = 0
    @Published var standHours: Int = 0

    @Published var heartRate: Int = 0
    @Published var restingHeartRate: Int = 0
    @Published var bloodOxygen: Int = 0
    @Published var stressScore: Int = 0
    @Published var hrv: Double = 0
    @Published var skinTempDelta: Double = 0
    @Published var systolic: Int = 0
    @Published var diastolic: Int = 0
    @Published var bloodSugar: Double = 0

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

    /// 生成一周合理的演示数据（阶段2替换为手表同步数据）
    private func seedDemoData() {
        let now = Date()
        let calendar = Calendar.current

        steps = 6421
        calories = 386
        exerciseMinutes = 42
        standHours = 9
        heartRate = 72
        restingHeartRate = 58
        bloodOxygen = 98
        stressScore = 31
        hrv = 48.5
        skinTempDelta = 0.2
        systolic = 118
        diastolic = 76
        bloodSugar = 5.4

        sleepMinutes = 7 * 60 + 23
        deepMinutes = 96
        lightMinutes = 268
        remMinutes = 85
        awakeMinutes = 14

        // 24h 心率采样
        heartRateSamples = (0..<96).map { i in
            let hour = Double(i) / 4.0
            let base = hour < 7 ? 58 : hour < 9 ? 82 : hour < 12 ? 74 : hour < 14 ? 88 : hour < 18 ? 78 : hour < 23 ? 68 : 60
            let noise = Double((i * 37) % 11) - 5
            return Sample(date: calendar.date(byAdding: .hour, value: i / 4 - 24, to: now)!, value: max(45, base + noise))
        }
        bloodOxygenSamples = (0..<48).map { i in
            Sample(date: calendar.date(byAdding: .hour, value: i / 2 - 24, to: now)!,
                   value: 96 + Double((i * 13) % 4))
        }
        stressSamples = (0..<48).map { i in
            Sample(date: calendar.date(byAdding: .hour, value: i / 2 - 24, to: now)!,
                   value: max(5, 28 + Double((i * 29) % 35) - 15))
        }

        ecgRecords = [
            ECGRecord(date: calendar.date(byAdding: .day, value: -1, to: now)!, result: "窦性心律", bpm: 71, durationSeconds: 30),
            ECGRecord(date: calendar.date(byAdding: .day, value: -3, to: now)!, result: "窦性心律", bpm: 68, durationSeconds: 30),
            ECGRecord(date: calendar.date(byAdding: .day, value: -6, to: now)!, result: "窦性心律", bpm: 74, durationSeconds: 30)
        ]

        sportRecords = [
            SportRecord(date: calendar.date(byAdding: .day, value: -1, to: now)!, type: "户外跑步", distanceKm: 5.24, durationMinutes: 32, calories: 341, avgHeartRate: 148),
            SportRecord(date: calendar.date(byAdding: .day, value: -2, to: now)!, type: "户外骑行", distanceKm: 12.8, durationMinutes: 51, calories: 388, avgHeartRate: 126),
            SportRecord(date: calendar.date(byAdding: .day, value: -5, to: now)!, type: "健身", distanceKm: 0, durationMinutes: 46, calories: 233, avgHeartRate: 112)
        ]
    }

    var sleepTotalHours: Double { Double(sleepMinutes) / 60 }
    var stepProgress: Double { Double(steps) / Double(max(stepGoal, 1)) }
    var exerciseProgress: Double { Double(exerciseMinutes) / 30.0 }
    var standProgress: Double { Double(standHours) / 12.0 }
}
