import SwiftUI
import Charts

// MARK: - 心率详情（日/周/月 + 最值统计）
struct HeartRateDetailView: View {
    @EnvironmentObject var store: HealthStore
    @State private var range = 0
    private let ranges = ["日", "周", "月"]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("", selection: $range) {
                    ForEach(0..<3) { Text(ranges[$0]).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(icon: "heart.fill", iconColor: Theme.heartRed, title: "心率", trailing: "次/分")
                        Text("\(store.heartRate)")
                            .font(.oppo(44, weight: .bold))
                        Chart(store.heartRateSamples) {
                            LineMark(x: .value("t", $0.date), y: .value("bpm", $0.value))
                                .foregroundStyle(Theme.heartRed)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("t", $0.date), y: .value("bpm", $0.value))
                                .foregroundStyle(.linearGradient(colors: [Theme.heartRed.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                statRow
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("心率")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            StatCell(title: "最高", value: "\(maxHeart)", unit: "次/分", color: Theme.heartRed)
            StatCell(title: "最低", value: "\(minHeart)", unit: "次/分", color: Theme.accentCyan)
            StatCell(title: "静息", value: "\(store.restingHeartRate)", unit: "次/分", color: Theme.bpPurple)
        }
        .padding(.horizontal, 16)
    }

    private var maxHeart: Int { Int(store.heartRateSamples.map(\.value).max() ?? 0) }
    private var minHeart: Int { Int(store.heartRateSamples.map(\.value).min() ?? 0) }
}

struct StatCell: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.oppo(12)).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.oppo(20, weight: .bold)).foregroundColor(color)
                Text(unit).font(.oppo(10)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 睡眠详情（阶段堆叠图）
struct SleepDetailView: View {
    @EnvironmentObject var store: HealthStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        CardHeader(icon: "bed.double.fill", iconColor: Theme.sleepIndigo, title: "睡眠时长")
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", store.sleepTotalHours)).font(.oppo(44, weight: .bold))
                            Text("小时").font(.oppo(15)).foregroundColor(.secondary)
                            Text(String(format: "%d", store.sleepMinutes % 60)).font(.oppo(44, weight: .bold))
                            Text("分").font(.oppo(15)).foregroundColor(.secondary)
                        }
                        SleepStageBar(deep: store.deepMinutes, light: store.lightMinutes, rem: store.remMinutes, awake: store.awakeMinutes)
                            .frame(height: 24)
                    }
                }
                .padding(.horizontal, 16)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(icon: "chart.bar.fill", iconColor: Theme.sleepIndigo, title: "睡眠结构")
                        stageRow("深睡", store.deepMinutes, Theme.sleepIndigo)
                        stageRow("浅睡", store.lightMinutes, Theme.sleepIndigo.opacity(0.55))
                        stageRow("快速眼动", store.remMinutes, Theme.accentPurple.opacity(0.7))
                        stageRow("清醒", store.awakeMinutes, Color(.systemGray4))
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("睡眠")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stageRow(_ name: String, _ minutes: Int, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(name).font(.oppo(14)).frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.1f 小时", Double(minutes) / 60)).font(.oppo(14, weight: .medium))
            Text(String(format: "%.0f%%", Double(minutes) / Double(max(store.sleepMinutes, 1)) * 100))
                .font(.oppo(13)).foregroundColor(.secondary).frame(width: 46, alignment: .trailing)
        }
    }
}

struct SleepStageBar: View {
    let deep: Int, light: Int, rem: Int, awake: Int
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                seg(deep, Theme.sleepIndigo, geo.size.width)
                seg(light, Theme.sleepIndigo.opacity(0.55), geo.size.width)
                seg(rem, Theme.accentPurple.opacity(0.7), geo.size.width)
                seg(awake, Color(.systemGray4), geo.size.width)
            }
        }
    }
    private func seg(_ m: Int, _ c: Color, _ w: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(c)
            .frame(width: max(4, w * CGFloat(m) / CGFloat(max(deep + light + rem + awake, 1))))
    }
}

// MARK: - 血氧详情
struct BloodOxygenDetailView: View {
    @EnvironmentObject var store: HealthStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(icon: "lungs.fill", iconColor: Theme.oxygenBlue, title: "血氧饱和度", trailing: "%")
                        Text("\(store.bloodOxygen)").font(.oppo(44, weight: .bold))
                        Chart(store.bloodOxygenSamples) {
                            LineMark(x: .value("t", $0.date), y: .value("spo2", $0.value))
                                .foregroundStyle(Theme.oxygenBlue)
                                .interpolationMethod(.catmullRom)
                        }
                        .chartYScale(domain: 88...100)
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    StatCell(title: "最低", value: "\(Int(store.bloodOxygenSamples.map(\.value).min() ?? 0))", unit: "%", color: Theme.heartRed)
                    StatCell(title: "平均", value: "\(Int(store.bloodOxygenSamples.map(\.value).reduce(0, +) / Double(max(store.bloodOxygenSamples.count, 1))))", unit: "%", color: Theme.oxygenBlue)
                    StatCell(title: "状态", value: "正常", unit: "", color: .green)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("血氧")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 压力详情
struct StressDetailView: View {
    @EnvironmentObject var store: HealthStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(icon: "brain.head.profile", iconColor: Theme.stressOrange, title: "压力指数")
                        Text("\(store.stressScore)").font(.oppo(44, weight: .bold))
                        Chart(store.stressSamples) {
                            AreaMark(x: .value("t", $0.date), y: .value("s", $0.value))
                                .foregroundStyle(.linearGradient(colors: [Theme.stressOrange.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("t", $0.date), y: .value("s", $0.value))
                                .foregroundStyle(Theme.stressOrange)
                                .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    StatCell(title: "放松", value: "0-39", unit: "", color: .green)
                    StatCell(title: "中度", value: "40-59", unit: "", color: Theme.stressOrange)
                    StatCell(title: "较高", value: "60+", unit: "", color: Theme.heartRed)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("压力")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 血压详情
struct BloodPressureDetailView: View {
    @EnvironmentObject var store: HealthStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(icon: "scalemass.fill", iconColor: Theme.bpPurple, title: "血压", trailing: "mmHg")
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(store.systolic)/\(store.diastolic)").font(.oppo(44, weight: .bold))
                        }
                        Text("收缩压/舒张压").font(.oppo(12)).foregroundColor(.secondary)
                        Text("正常").font(.oppo(14, weight: .semibold)).foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("血压")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 活动详情
struct ActivityDetailView: View {
    @EnvironmentObject var store: HealthStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(spacing: 18) {
                        ActivityRingsView(move: store.stepProgress, exercise: store.exerciseProgress, stand: store.standProgress)
                            .frame(width: 160, height: 160)
                        RingStat(color: Theme.activityRed, label: "步数", value: "\(store.steps)", goal: "目标 \(store.stepGoal)")
                        RingStat(color: Theme.activityGreen, label: "活动消耗", value: "\(store.calories) 千卡", goal: "目标 400 千卡")
                        RingStat(color: Theme.activityCyan, label: "站立", value: "\(store.standHours) 小时", goal: "目标 12 小时")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("活动")
        .navigationBarTitleDisplayMode(.inline)
    }
}
