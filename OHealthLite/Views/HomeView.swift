import SwiftUI
import Charts

/// 首页 —— 按 OPPO 健康 6.11.0 官方截图 1:1 复刻
/// 结构：大标题「健康」→ 健康云卡 → 活动四环卡 → 健康趋势/AI助手 → 指标入口卡网格 → 编辑 → 活动推荐
struct HomeView: View {
    @EnvironmentObject var store: HealthStore
    @EnvironmentObject var ble: WatchBLEManager
    @State private var cloudCardDismissed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if !cloudCardDismissed { cloudCard }
                    activityCard
                    HStack(spacing: 12) { trendCard; aiCard }
                    metricGrid
                    editButton
                    activitySection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Theme.pageBG)
            .navigationTitle("健康")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 健康云服务卡
    private var cloudCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(LinearGradient(colors: [Color(hex: 0x4A8CFA), Color(hex: 0x2F6BF6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("开启健康云服务").font(.oppo(16, weight: .semibold))
                Text("为避免您的个人数据丢失，请开启健康云服务，备份到云端")
                    .font(.oppo(13)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 8) {
                Button("忽略") { withAnimation { cloudCardDismissed = true } }
                Button("去开启") {}
            }
            .font(.oppo(14, weight: .medium))
            .buttonStyle(.plain)
            .tint(Color(hex: 0x2F6BF6))
        }
        .padding(16)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - 活动四环卡（步数/消耗/锻炼时长/活动次数）
    private var activityCard: some View {
        NavigationLink { ActivityDetailView() } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 18) {
                    activityStat("步数", "\(store.steps)", "\(store.stepGoal) 步")
                    activityStat("锻炼时长", "\(store.exerciseMinutes)", "\(store.exerciseGoal) 分钟")
                }
                Spacer(minLength: 6)
                QuadrupleRingsView(r1: store.stepProgress, r2: store.calorieProgress,
                                   r3: store.exerciseProgress, r4: store.workoutsProgress)
                    .frame(width: 96, height: 96)
                    .padding(.horizontal, 6)
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 18) {
                    activityStat("消耗", "\(store.calories)", "\(store.calorieGoal) 千卡", alignTrailing: true)
                    activityStat("活动次数", "\(store.workouts)", "\(store.workoutsGoal) 次", alignTrailing: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func activityStat(_ name: String, _ value: String, _ goal: String, alignTrailing: Bool = false) -> some View {
        VStack(alignment: alignTrailing ? .trailing : .leading, spacing: 0) {
            Text(name).font(.oppo(12)).foregroundColor(.secondary)
            Text(value).font(.oppo(22, weight: .semibold))
            Text(goal).font(.oppo(12)).foregroundColor(.secondary)
        }
    }

    // MARK: - 健康趋势 / AI 健康助手
    private var trendCard: some View {
        featureCard(title: "健康趋势", desc: "持续记录健康数据，可以获取趋势分析",
                    button: "去了解", icon: "chart.line.uptrend.xyaxis",
                    colors: [Color(hex: 0x2FD8E8), Color(hex: 0x18B8D0)]) {
            Text("趋势分析即将上线").font(.oppo(15))
        }
    }

    private var aiCard: some View {
        featureCard(title: "AI 健康助手", desc: "如何改善睡眠不足?\n猜你想问",
                    button: "去问问", icon: "sparkles",
                    colors: [Color(hex: 0xFF5E7D), Color(hex: 0x5B5FFA), Color(hex: 0x35C759)]) {
            Text("AI 健康助手为云端能力，本地版本暂不可用").font(.oppo(15))
        }
    }

    // MARK: - 指标入口卡网格（官方 15 卡）
    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            featureCard(title: "心率", desc: "记录心脏跳动频率", button: "去了解",
                        icon: "heart.fill", colors: [Color(hex: 0xFF5E7D), Color(hex: 0xF5335B)]) {
                HeartRateDetailView()
            }
            featureCard(title: "睡眠", desc: "监测睡眠，了解睡眠质量", button: "去了解",
                        icon: "moon.zzz.fill", colors: [Color(hex: 0x6E6EFA), Color(hex: 0x4048F0)]) {
                SleepDetailView()
            }
            featureCard(title: "血压", badge: "推荐", desc: "加入血压健康研究，无感评估高血压风险", button: "去记录",
                        icon: "gauge.with.needle", colors: [Color(hex: 0xFF5E7D), Color(hex: 0xF5335B)]) {
                BloodPressureDetailView()
            }
            featureCard(title: "睡眠呼吸暂停", desc: "科学评估睡眠呼吸暂停风险", button: "去了解",
                        icon: "zzz", colors: [Color(hex: 0x5E6BFA), Color(hex: 0x3A48E8)]) {
                SleepDetailView()
            }
            featureCard(title: "身心状态", desc: "监测身体疲劳度和心理压力状态", button: "去了解",
                        icon: "smileyface.fill", colors: [Color(hex: 0xFFC24B), Color(hex: 0xFFAB00)]) {
                StressDetailView()
            }
            featureCard(title: "日照时长", desc: "自动监测户外日光照射时长", button: "去了解",
                        icon: "sun.max.fill", colors: [Color(hex: 0xFFB340), Color(hex: 0xFF9500)]) {
                Text("日照时长需要手表光照传感器数据").font(.oppo(15))
            }
            featureCard(title: "生理周期", desc: "追踪预测你的生理周期", button: "去了解",
                        icon: "leaf.fill", colors: [Color(hex: 0xFF7A9E), Color(hex: 0xF5335B)]) {
                Text("生理周期记录").font(.oppo(15))
            }
            featureCard(title: "血氧", desc: "测量血氧饱和度", button: "去了解",
                        icon: "drop.fill", colors: [Color(hex: 0xFF6B6B), Color(hex: 0xF02D4A)]) {
                BloodOxygenDetailView()
            }
            featureCard(title: "血糖", desc: "持续监测血糖水平", button: "去了解",
                        icon: "hexagon.fill", colors: [Color(hex: 0xFF5E7D), Color(hex: 0xF5335B)]) {
                Text("血糖监测需要血糖仪数据").font(.oppo(15))
            }
            featureCard(title: "60 秒体检", desc: "全面检测和评估身体健康状态", button: "去了解",
                        icon: "stethoscope", colors: [Color(hex: 0xFF5E7D), Color(hex: 0xF5335B)]) {
                Text("60 秒体检需要手表配合测量").font(.oppo(15))
            }
            featureCard(title: "心电", desc: "记录心脏跳动节奏，分析心电图", button: "去了解",
                        icon: "waveform.path.ecg", colors: [Color(hex: 0xFF5E7D), Color(hex: 0xF5335B)]) {
                ECGView()
            }
            featureCard(title: "手腕温度", desc: "监测腕部皮肤温度，了解体征变化", button: "去了解",
                        icon: "thermometer.medium", colors: [Color(hex: 0xB36BFA), Color(hex: 0x9C3BF5)]) {
                Text("手腕温度来自夜间佩戴监测").font(.oppo(15))
            }
            featureCard(title: "体重", desc: "记录体重，设置目标体重", button: "记录体重",
                        icon: "scalemass.fill", colors: [Color(hex: 0x1BD9D0), Color(hex: 0x00B8B4)]) {
                Text("体重记录").font(.oppo(15))
            }
            featureCard(title: "家人健康", desc: "查看家人的运动健康数据", button: "添加家人",
                        icon: "house.fill", colors: [Color(hex: 0x3E8EFA), Color(hex: 0x1F6EF5)]) {
                Text("家人健康需要账号登录").font(.oppo(15))
            }
            featureCard(title: "健康旅程", desc: "记录每天重要的运动健康事件", button: "去了解",
                        icon: "heart.text.square.fill", colors: [Color(hex: 0x4A8CFA), Color(hex: 0x2F6BF6)]) {
                Text("健康旅程").font(.oppo(15))
            }
        }
    }

    /// 官方指标卡：标题(+徽章) + 描述 + 左胶囊按钮 + 右圆形渐变图标
    private func featureCard<D: View>(title: String, badge: String? = nil, desc: String,
                                      button: String, icon: String, colors: [Color],
                                      @ViewBuilder destination: () -> D) -> some View {
        NavigationLink { destination() } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(title).font(.oppo(14)).foregroundColor(.secondary)
                    if let badge {
                        Text(badge)
                            .font(.oppo(10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: 0xFF9500))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                Text(desc)
                    .font(.oppo(16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                Spacer(minLength: 10)
                HStack(alignment: .center, spacing: 8) {
                    Text(button)
                        .font(.oppo(13))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color(hex: 0xF2F2F7))
                        .clipShape(Capsule())
                    Spacer(minLength: 4)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient(colors: colors,
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 编辑
    private var editButton: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil.tip")
            Text("编辑").font(.oppo(16, weight: .medium))
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - 活动推荐
    private var activitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("活动推荐").font(.oppo(20, weight: .bold))
                Spacer()
                HStack(spacing: 2) {
                    Text("查看更多").font(.oppo(14))
                    Image(systemName: "chevron.right").font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            // 官方 banner：运营活动图，本地用渐变占位复刻排版
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(hex: 0xE8A24C), Color(hex: 0xC96A2B), Color(hex: 0x8A4A22)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 4) {
                    Text("11月跑量挑战赛")
                        .font(.oppo(24, weight: .bold))
                        .foregroundColor(.white)
                        .italic()
                    Text("寒意渐起秋渐浓，跑者无畏步如风")
                        .font(.oppo(12))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

/// 官方活动四环（2x2 排列；空态灰环）
struct QuadrupleRingsView: View {
    var r1: Double   // 步数（左上）
    var r2: Double   // 消耗（右上）
    var r3: Double   // 锻炼（左下）
    var r4: Double   // 次数（右下）

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2
            ZStack {
                ring(1, color: Color(.systemGray5), size: w, center: CGPoint(x: w/2, y: h/2))
                ring(1, color: Color(.systemGray5), size: w, center: CGPoint(x: w*1.5, y: h/2))
                ring(1, color: Color(.systemGray5), size: w, center: CGPoint(x: w/2, y: h*1.5))
                ring(1, color: Color(.systemGray5), size: w, center: CGPoint(x: w*1.5, y: h*1.5))
                if r1 > 0 { ring(r1, color: Theme.activityRed, size: w, center: CGPoint(x: w/2, y: h/2)) }
                if r2 > 0 { ring(r2, color: Theme.activityCyan, size: w, center: CGPoint(x: w*1.5, y: h/2)) }
                if r3 > 0 { ring(r3, color: Theme.activityGreen, size: w, center: CGPoint(x: w/2, y: h*1.5)) }
                if r4 > 0 { ring(r4, color: Theme.stressOrange, size: w, center: CGPoint(x: w*1.5, y: h*1.5)) }
            }
        }
    }

    private func ring(_ ratio: Double, color: Color, size: CGFloat, center: CGPoint) -> some View {
        Circle()
            .trim(from: 0, to: ratio)
            .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: size - 10, height: size - 10)
            .position(center)
    }
}
