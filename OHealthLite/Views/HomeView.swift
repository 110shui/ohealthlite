import SwiftUI
import Charts

/// 首页 —— 对齐官方「健康」Tab：活动三环 + 指标卡瀑布流
struct HomeView: View {
    @EnvironmentObject var store: HealthStore
    @EnvironmentObject var ble: WatchBLEManager

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 6 ? "凌晨好" : h < 12 ? "早上好" : h < 14 ? "中午好" : h < 18 ? "下午好" : "晚上好"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    connectionBanner
                    activityCard
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        heartRateCard
                        sleepCard
                        bloodOxygenCard
                        stressCard
                    }
                    metricsGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.pageBG)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(greeting)，加油")
                            .font(.oppo(22, weight: .bold))
                        Text(Self.dateText)
                            .font(.oppo(13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    static var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    // MARK: - 子视图

    private var connectionBanner: some View {
        Group {
            if ble.connectedWatch != nil {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("手表已连接：\(ble.connectedWatch?.name ?? "OPPO Watch")")
                    Spacer()
                }
                .font(.oppo(13))
                .padding(12)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                NavigationLink {
                    DeviceView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "applewatch")
                            .foregroundColor(Theme.accentCyan)
                        Text("连接手表，同步今日数据")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .font(.oppo(13))
                    .padding(12)
                    .background(Theme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var activityCard: some View {
        NavigationLink { ActivityDetailView() } label: {
            HStack(spacing: 20) {
                ActivityRingsView(move: store.stepProgress,
                                  exercise: store.exerciseProgress,
                                  stand: store.standProgress)
                    .frame(width: 110, height: 110)
                VStack(alignment: .leading, spacing: 10) {
                    RingStat(color: Theme.activityRed, label: "步数", value: "\(store.steps)", goal: "目标 \(store.stepGoal)")
                    RingStat(color: Theme.activityGreen, label: "活动", value: "\(store.exerciseMinutes) 分钟", goal: "目标 30 分钟")
                    RingStat(color: Theme.activityCyan, label: "站立", value: "\(store.standHours) 小时", goal: "目标 12 小时")
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .card()
    }

    private var heartRateCard: some View {
        NavigationLink { HeartRateDetailView() } label: {
            MetricCard(icon: "heart.fill", iconColor: Theme.heartRed, title: "心率",
                       value: store.heartRate > 0 ? "\(store.heartRate)" : "--", unit: "次/分",
                       sub: "静息 \(store.restingHeartRate) 次/分") {
                Chart(store.heartRateSamples.suffix(24)) {
                    LineMark(x: .value("t", $0.date), y: .value("bpm", $0.value))
                        .foregroundStyle(Theme.heartRed)
                        .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .buttonStyle(.plain)
    }

    private var sleepCard: some View {
        NavigationLink { SleepDetailView() } label: {
            MetricCard(icon: "bed.double.fill", iconColor: Theme.sleepIndigo, title: "睡眠",
                       value: String(format: "%.1f", store.sleepTotalHours), unit: "小时",
                       sub: String(format: "深睡 %.1f 小时", Double(store.deepMinutes) / 60)) {
                HStack(spacing: 4) {
                    bar(store.deepMinutes, color: Theme.sleepIndigo)
                    bar(store.lightMinutes, color: Theme.sleepIndigo.opacity(0.55))
                    bar(store.remMinutes, color: Theme.accentPurple.opacity(0.6))
                    bar(store.awakeMinutes, color: Color(.systemGray4))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var bloodOxygenCard: some View {
        NavigationLink { BloodOxygenDetailView() } label: {
            MetricCard(icon: "lungs.fill", iconColor: Theme.oxygenBlue, title: "血氧",
                       value: store.bloodOxygen > 0 ? "\(store.bloodOxygen)" : "--", unit: "%",
                       sub: "正常范围 95%~100%") {
                Chart(store.bloodOxygenSamples.suffix(20)) {
                    LineMark(x: .value("t", $0.date), y: .value("spo2", $0.value))
                        .foregroundStyle(Theme.oxygenBlue)
                        .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 90...100)
            }
        }
        .buttonStyle(.plain)
    }

    private var stressCard: some View {
        NavigationLink { StressDetailView() } label: {
            MetricCard(icon: "brain.head.profile", iconColor: Theme.stressOrange, title: "压力",
                       value: "\(store.stressScore)", unit: "",
                       sub: store.stressScore < 40 ? "状态放松" : "中度压力") {
                Chart(store.stressSamples.suffix(20)) {
                    AreaMark(x: .value("t", $0.date), y: .value("s", $0.value))
                        .foregroundStyle(.linearGradient(colors: [Theme.stressOrange.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("t", $0.date), y: .value("s", $0.value))
                        .foregroundStyle(Theme.stressOrange)
                        .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .buttonStyle(.plain)
    }

    /// 血压 / HRV / 体温 / 血糖 / 心电 / 运动 六宫格
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            simpleCard(icon: "waveform.path.ecg.rectangle.fill", color: Theme.heartRed, title: "心电",
                       value: store.ecgRecords.first?.result ?? "测量") { ECGView() }
            simpleCard(icon: "scalemass.fill", color: Theme.bpPurple, title: "血压",
                       value: "\(store.systolic)/\(store.diastolic)", sub: "mmHg") { BloodPressureDetailView() }
            simpleCard(icon: " thermometer.medium", color: Theme.tempMint, title: "体温",
                       value: store.skinTempDelta >= 0 ? "+\(String(format: "%.1f", store.skinTempDelta))" : String(format: "%.1f", store.skinTempDelta),
                       sub: "°C 体表温度偏差") { SleepDetailView() }
            simpleCard(icon: "heart.text.square.fill", color: Theme.accentPurple, title: "HRV",
                       value: String(format: "%.0f", store.hrv), sub: "ms 心率变异性") { HeartRateDetailView() }
            simpleCard(icon: "drop.fill", color: Theme.activityGreen, title: "血糖",
                       value: String(format: "%.1f", store.bloodSugar), sub: "mmol/L") { BloodPressureDetailView() }
            simpleCard(icon: "figure.run", color: Theme.stressOrange, title: "运动",
                       value: "\(store.sportRecords.count)", sub: "近一周记录") { SportView() }
        }
    }

    private func simpleCard<D: View>(icon: String, color: Color, title: String, value: String, sub: String? = nil, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink { destination() } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon.trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                    Text(title).font(.oppo(14, weight: .medium)).foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.secondary)
                }
                Text(value).font(.oppo(22, weight: .bold))
                if let sub {
                    Text(sub).font(.oppo(12)).foregroundColor(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func bar(_ minutes: Int, color: Color) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: max(4, geo.size.width * CGFloat(minutes) / CGFloat(max(store.sleepMinutes, 1))))
        }
    }
}

struct RingStat: View {
    let color: Color
    let label: String
    let value: String
    let goal: String
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.oppo(12)).foregroundColor(.secondary)
                Text(value).font(.oppo(16, weight: .semibold))
                Text(goal).font(.oppo(10)).foregroundColor(.secondary)
            }
        }
    }
}

extension View {
    func card() -> some View {
        padding(16)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
