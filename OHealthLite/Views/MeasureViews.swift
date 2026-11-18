import SwiftUI

/// 测定设置（心率/血氧自动测定间隔）+ 手动测量，官方 App 同款能力
struct MeasureSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ohealth.hrInterval") private var hrInterval = 30
    @AppStorage("ohealth.spo2Interval") private var spo2Interval = 60
    let hrOptions = [15, 30, 60, 120]
    let spo2Options = [15, 60, 300, 600]

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("心率自动测定间隔", selection: $hrInterval) {
                        ForEach(hrOptions, id: \.self) { Text("\($0) 秒").tag($0) }
                    }
                    Picker("血氧自动测定间隔", selection: $spo2Interval) {
                        ForEach(spo2Options, id: \.self) { Text("\($0 == 600 ? 300 : $0) 秒").tag($0) }
                    }
                } footer: {
                    Text("设置将下发到手表数据桥，按间隔自动测定并保存记录；手表与手机记录实时同步。")
                }
            }
            .navigationTitle("测定设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        WatchBridgeClient.shared.sendConfig(hrInterval: hrInterval, spo2Interval: spo2Interval)
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 测量控制卡（心率/血氧详情页共用）
struct MeasureCard: View {
    @EnvironmentObject var store: HealthStore
    @State private var showSettings = false
    @State private var connected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("测量")
                    .font(.oppo(16, weight: .semibold))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Label("测定设置", systemImage: "gearshape")
                        .font(.oppo(13))
                }
            }
            if store.measuring {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在测量，请保持佩戴静止…")
                        .font(.oppo(14)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                Button {
                    store.measuring = true
                    store.lastMeasureResult = ""
                    WatchBridgeClient.shared.requestMeasure()
                    // 12 秒无响应自动复位
                    DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                        if store.measuring { store.measuring = false }
                    }
                } label: {
                    Text("立即测量")
                        .font(.oppo(16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(connected ? Color.black : Color.gray)
                        .cornerRadius(24)
                }
                .disabled(!connected)
                if !connected {
                    Text("需要先在设备页连接手表数据桥")
                        .font(.oppo(12)).foregroundColor(.secondary)
                }
                if !store.lastMeasureResult.isEmpty {
                    Text(store.lastMeasureResult)
                        .font(.oppo(15, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showSettings) { MeasureSettingsSheet() }
        .onAppear { connected = WatchBridgeClient.shared.isConnected }
        .onReceive(WatchBridgeClient.shared.$isConnected) { connected = $0 }
    }
}

// MARK: - 血压详情（手动录入 + 记录列表 + 趋势）
struct BloodPressureInputRow: View {
    @EnvironmentObject var store: HealthStore
    @State private var sysText = ""
    @State private var diaText = ""
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("手动录入")
                .font(.oppo(15, weight: .semibold))
            HStack(spacing: 10) {
                TextField("收缩压", text: $sysText, prompt: Text("收缩压").foregroundColor(.secondary))
                    .keyboardType(.numberPad)
                    .font(.oppo(20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .frame(height: 48)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Text("/")
                    .font(.oppo(18)).foregroundColor(.secondary)
                TextField("舒张压", text: $diaText, prompt: Text("舒张压").foregroundColor(.secondary))
                    .keyboardType(.numberPad)
                    .font(.oppo(20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .frame(height: 48)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Button {
                    guard let sys = Int(sysText), let dia = Int(diaText) else {
                        message = "请输入有效数值"; return
                    }
                    store.addBP(systolic: sys, diastolic: dia)
                    sysText = ""; diaText = ""
                    message = "已保存 \(sys)/\(dia) mmHg"
                } label: {
                    Text("保存")
                        .font(.oppo(15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .cornerRadius(24)
                }
            }
            if !message.isEmpty {
                Text(message).font(.oppo(13)).foregroundColor(.green)
            }
        }
    }
}

/// 血压趋势条形图（官方样式：竖条排列）
struct BPChart: View {
    let records: [HealthStore.BPRecord]

    var body: some View {
        if records.count < 2 {
            VStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 36)).foregroundColor(.secondary)
                Text("暂无血压记录，手动录入后生成趋势")
                    .font(.oppo(14)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).frame(height: 160)
        } else {
            Chart(Array(records.suffix(20).enumerated()), id: \.element.id) { _, rec in
                LineMark(x: .value("t", rec.date), y: .value("sys", rec.systolic))
                    .foregroundStyle(Theme.bpPurple)
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("t", rec.date), y: .value("dia", rec.diastolic))
                    .foregroundStyle(Theme.accentCyan)
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 40...180)
            .frame(height: 180)
        }
    }
}

// MARK: - 短视频遥控卡（设备页）
struct RemoteControlCard: View {
    @State private var connected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.on.rectangle")
                    .foregroundColor(.red)
                Text("短视频遥控").font(.oppo(16, weight: .semibold))
                Spacer()
                Text(connected ? "已联动" : "未连接")
                    .font(.oppo(12))
                    .foregroundColor(connected ? .green : .secondary)
            }
            HStack(spacing: 12) {
                Button {
                    RemoteControlManager.shared.handle("VOLDOWN")
                } label: {
                    Label("上一条", systemImage: "backward.end.fill")
                        .font(.oppo(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                }
                .disabled(!connected)
                Button {
                    RemoteControlManager.shared.handle("VOLUP")
                } label: {
                    Label("下一条", systemImage: "forward.end.fill")
                        .font(.oppo(15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(20)
                }
                .disabled(!connected)
            }
            Text("手表打开数据桥 App 点「下一条视频」即可翻页；手机端抖音需开启「音量键翻页」。")
                .font(.oppo(12)).foregroundColor(.secondary)
        }
        .onAppear { connected = WatchBridgeClient.shared.isConnected }
        .onReceive(WatchBridgeClient.shared.$isConnected) { connected = $0 }
    }
}
