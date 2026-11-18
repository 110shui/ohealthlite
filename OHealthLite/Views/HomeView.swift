import SwiftUI

/// 首页 —— 参考 OPPO 健康 6.x 的卡片式布局
struct HomeView: View {
    @EnvironmentObject var ble: WatchBLEManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    connectionBanner
                    HealthCardGrid()
                    ECGEntryCard()
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("健康")
        }
    }

    private var connectionBanner: some View {
        HStack {
            Image(systemName: ble.connectionPhase == .ready ? "checkmark.circle.fill" : "applewatch")
                .foregroundStyle(ble.connectionPhase == .ready ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(ble.connectedWatch?.name ?? "未连接手表")
                    .font(.subheadline.weight(.semibold))
                Text(ble.connectionPhase.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink {
                DeviceView()
            } label: {
                Text(ble.connectionPhase == .ready ? "详情" : "去连接")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.red.opacity(0.12)))
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
}

/// 健康指标卡片网格（步数/心率/睡眠/血氧 占位）
struct HealthCardGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "步数", value: "--", unit: "步",
                       icon: "figure.walk", color: .orange)
            MetricCard(title: "心率", value: "--", unit: "bpm",
                       icon: "heart.fill", color: .red)
            MetricCard(title: "睡眠", value: "--", unit: "小时",
                       icon: "bed.double.fill", color: .indigo)
            MetricCard(title: "血氧", value: "--", unit: "%",
                       icon: "lungs.fill", color: .teal)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
}

/// 心电入口卡（官方风格：红色渐变 + 大按钮引导）
struct ECGEntryCard: View {
    var body: some View {
        NavigationLink {
            ECGView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("心电图").font(.headline)
                    Text("30 秒测量 · 研究用途")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 34))
                    .foregroundStyle(.red)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.red.opacity(0.10), .red.opacity(0.04)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
    }
}
