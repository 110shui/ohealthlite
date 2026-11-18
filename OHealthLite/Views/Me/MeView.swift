import SwiftUI

/// 我的 Tab —— 对齐官方「我的」页：账号卡 + 目标 + 设置组
struct MeView: View {
    @AppStorage("nickname") private var nickname = "OPPO 用户"
    @AppStorage("goalSteps") private var goalSteps = 8000
    @AppStorage("goalCalories") private var goalCalories = 400

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    profileCard
                    goalsCard
                    settingsCard
                    aboutCard
                }
                .padding(16)
            }
            .background(Theme.pageBG)
            .navigationTitle("我的")
        }
    }

    private var profileCard: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Theme.accentCyan)
                VStack(alignment: .leading, spacing: 4) {
                    Text(nickname).font(.oppo(20, weight: .bold))
                    Text("本地模式 · 数据保存在本机")
                        .font(.oppo(12)).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
    }

    private var goalsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("我的目标").font(.oppo(16, weight: .semibold))
                Stepper(value: $goalSteps, in: 2000...30000, step: 500) {
                    HStack {
                        Image(systemName: "shoe.fill").foregroundColor(Theme.activityRed)
                        Text("每日步数").font(.oppo(14))
                        Spacer()
                        Text("\(goalSteps) 步").font(.oppo(14, weight: .semibold)).foregroundColor(.secondary)
                    }
                }
                Divider()
                Stepper(value: $goalCalories, in: 100...2000, step: 50) {
                    HStack {
                        Image(systemName: "flame.fill").foregroundColor(Theme.stressOrange)
                        Text("每日活动消耗").font(.oppo(14))
                        Spacer()
                        Text("\(goalCalories) 千卡").font(.oppo(14, weight: .semibold)).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var settingsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                settingRow("heart.circle.fill", Theme.heartRed, "心率警报")
                Divider().padding(.leading, 40)
                settingRow("moon.fill", Theme.sleepIndigo, "睡眠提醒")
                Divider().padding(.leading, 40)
                settingRow("figure.stand", Theme.activityGreen, "久坐提醒")
                Divider().padding(.leading, 40)
                settingRow("clock.fill", Theme.stressOrange, "久坐时间设置")
                Divider().padding(.leading, 40)
                settingRow("square.and.arrow.up.fill", Theme.accentCyan, "数据导出")
            }
        }
    }

    private func settingRow(_ icon: String, _ color: Color, _ name: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 28)
            Text(name).font(.oppo(15))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("关于").font(.oppo(16, weight: .semibold))
                Text("OHealthLite 2.0 · 界面结构与文案基于 OPPO 健康 6.11.0 复刻")
                    .font(.oppo(12)).foregroundColor(.secondary)
                Text("数据通道复用官方 BLE 协议逆向成果（aa15/bb15 双通道）。账号、健康云、社区等依赖官方服务器的功能为本地替代实现。")
                    .font(.oppo(12)).foregroundColor(.secondary)
            }
        }
    }
}
