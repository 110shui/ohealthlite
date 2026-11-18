import SwiftUI

/// 运动 Tab —— 对齐官方「运动」页：开始运动 + 运动记录
struct SportView: View {
    @EnvironmentObject var store: HealthStore
    @State private var showStart = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    startCard
                    recordList
                }
                .padding(16)
            }
            .background(Theme.pageBG)
            .navigationTitle("运动")
        }
    }

    private var startCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("开始运动")
                    .font(.oppo(18, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    sportType("户外跑步", "figure.run", Theme.activityRed)
                    sportType("户外骑行", "bicycle", Theme.activityCyan)
                    sportType("健身", "dumbbell.fill", Theme.activityGreen)
                    sportType("游泳", "figure.pool.swim", Theme.oxygenBlue)
                    sportType("室内跑步", "treadmill", Theme.heartRed)
                    sportType("瑜伽", "figure.mind.and.body", Theme.accentPurple)
                    sportType("跳绳", "figure.jumprope", Theme.stressOrange)
                    sportType("健走", "figure.walk", Theme.bpPurple)
                }
            }
        }
    }

    private func sportType(_ name: String, _ icon: String, _ color: Color) -> some View {
        Button {
            showStart = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(name).font(.oppo(11)).foregroundColor(.primary)
            }
        }
    }

    private var recordList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("运动记录")
                    .font(.oppo(18, weight: .bold))
                if store.sportRecords.isEmpty {
                    Text("暂无运动记录，开始你的第一次运动吧")
                        .font(.oppo(13)).foregroundColor(.secondary)
                } else {
                    ForEach(store.sportRecords) { rec in
                        NavigationLink { SportRecordDetail(record: rec) } label: {
                            SportRecordRow(record: rec)
                        }
                        .buttonStyle(.plain)
                        if rec.id != store.sportRecords.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

struct SportRecordRow: View {
    let record: HealthStore.SportRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 18))
                .foregroundColor(Theme.activityRed)
                .frame(width: 40, height: 40)
                .background(Theme.activityRed.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(record.type).font(.oppo(15, weight: .medium)).foregroundColor(.primary)
                Text(Self.dateText(record.date)).font(.oppo(12)).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if record.distanceKm > 0 {
                    Text(String(format: "%.2f 公里", record.distanceKm))
                        .font(.oppo(15, weight: .semibold)).foregroundColor(.primary)
                }
                Text("\(record.durationMinutes) 分钟 · \(record.calories) 千卡")
                    .font(.oppo(11)).foregroundColor(.secondary)
            }
        }
    }

    static func dateText(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: d)
    }
}

struct SportRecordDetail: View {
    let record: HealthStore.SportRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(spacing: 6) {
                        Text(record.type).font(.oppo(16)).foregroundColor(.secondary)
                        Text(String(format: "%.2f", record.distanceKm))
                            .font(.oppo(52, weight: .bold))
                        Text("公里").font(.oppo(13)).foregroundColor(.secondary)
                        Text(SportRecordRow.dateText(record.date)).font(.oppo(12)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    StatCell(title: "时长", value: "\(record.durationMinutes)", unit: "分钟", color: Theme.activityCyan)
                    StatCell(title: "消耗", value: "\(record.calories)", unit: "千卡", color: Theme.activityRed)
                    StatCell(title: "平均心率", value: "\(record.avgHeartRate)", unit: "次/分", color: Theme.heartRed)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.pageBG)
        .navigationTitle("运动详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}
