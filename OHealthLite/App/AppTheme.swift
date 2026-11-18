import SwiftUI

/// 官方主题色（从 OHealth 6.11.0 框架二进制提取）
enum Theme {
    // 官方提取
    static let accentCyan   = Color(hex: 0x13DEFA)
    static let accentPurple = Color(hex: 0xAA0CD4)
    static let accentBlue   = Color(hex: 0x0A24DE)
    // OPPO 健康语义色
    static let heartRed     = Color(hex: 0xF4433C)
    static let sleepIndigo  = Color(hex: 0x5C6BC0)
    static let oxygenBlue   = Color(hex: 0x2D9CDB)
    static let stressOrange = Color(hex: 0xFF9800)
    static let activityRed   = Color(hex: 0xFA114F)
    static let activityGreen = Color(hex: 0x92E82A)
    static let activityCyan  = Color(hex: 0x00DDFF)
    static let tempMint     = Color(hex: 0x26C6DA)
    static let bpPurple     = Color(hex: 0x7E57C2)
    static let cardBG       = Color(.secondarySystemGroupedBackground)
    static let pageBG       = Color(.systemGroupedBackground)
}

extension Color {
    init(hex: UInt64) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension Font {
    static func oppo(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

/// 圆角卡片容器
struct Card<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// 卡片头部：图标 + 标题 + 右侧副文本
struct CardHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
            Text(title)
                .font(.oppo(15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.oppo(13))
                    .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
}

/// 三色活动圆环（活动/锻炼/站立）
struct ActivityRingsView: View {
    var move: Double      // 0...1
    var exercise: Double
    var stand: Double
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            RingTrack(color: Theme.activityRed.opacity(0.15), ratio: 1)
            RingTrack(color: Theme.activityGreen.opacity(0.15), ratio: 1).scaleEffect(0.78)
            RingTrack(color: Theme.activityCyan.opacity(0.15), ratio: 1).scaleEffect(0.56)
            RingArc(color: Theme.activityRed, ratio: min(move, 1))
            RingArc(color: Theme.activityGreen, ratio: min(exercise, 1)).scaleEffect(0.78)
            RingArc(color: Theme.activityCyan, ratio: min(stand, 1)).scaleEffect(0.56)
        }
    }

    struct RingTrack: View {
        let color: Color
        let ratio: CGFloat
        var body: some View {
            Circle()
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
    struct RingArc: View {
        let color: Color
        let ratio: Double
        var body: some View {
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
