import SwiftUI

/// 心电测量页 —— UI 复刻官方 OPPO ECG App：
/// 大圆环按钮 + 静止指引 + 30 秒倒计时 + 结果页
struct ECGView: View {
    @EnvironmentObject var ble: WatchBLEManager
    @State private var measuring = false
    @State private var remaining = 30
    @State private var timer: Timer?
    @State private var finished = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                if finished {
                    resultView
                } else {
                    guideView
                }
            }
            .padding()
            .navigationTitle("心电图")
            .onDisappear { stopTimer() }
        }
    }

    // MARK: - 测量引导（复刻官方：圆环按钮 + 指引文案）
    private var guideView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.15), lineWidth: 14)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: measuring ? progress : 1)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .animation(.linear(duration: 1), value: remaining)
                VStack(spacing: 4) {
                    if measuring {
                        Text("\(remaining)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                        Text("秒").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                    }
                }
            }

            if measuring {
                Text("请保持手指按住表冠，手臂平放")
                    .font(.subheadline).foregroundStyle(.secondary)
                if ble.connectionPhase == .ready {
                    Text("数据通道已就绪（notify 接收中）")
                        .font(.caption2).foregroundStyle(.green)
                } else {
                    Text("⚠️ 手表未连接：当前为 UI 演示模式")
                        .font(.caption2).foregroundStyle(.orange)
                }
            } else {
                VStack(spacing: 10) {
                    Text("测量方法").font(.subheadline.weight(.semibold))
                    Text("1. 手表戴紧，手臂平放\n2. 另一只手手指按住金属表冠\n3. 保持静止 30 秒")
                        .font(.footnote).multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                measuring ? stopTimer() : startMeasure()
            } label: {
                Text(measuring ? "停止" : "开始测量")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 40)

            Text("研究用途 · 非医疗诊断依据")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - 结果页（复刻官方结果布局）
    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("研究模式").font(.title2.bold())
            Text("已捕获 BLE 通道数据 \(ble.latestNotifyData?.count ?? 0) 字节（notify 通道）\n完整分析需接入认证协议（后续版本）")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("重新测量") {
                finished = false
            }
            .buttonStyle(.bordered)
        }
    }

    private var progress: Double { Double(30 - remaining) / 30.0 }

    private func startMeasure() {
        remaining = 30
        measuring = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if remaining <= 1 {
                t.invalidate()
                measuring = false
                finished = true
            } else {
                remaining -= 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        measuring = false
    }
}
