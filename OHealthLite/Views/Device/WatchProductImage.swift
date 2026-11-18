import SwiftUI

/// SwiftUI 矢量绘制的 OPPO Watch X3 产品图
/// 橙色氟橡胶表带 + 钛灰表圈 + 黑色四环表盘（环色随真实活动数据点亮）
struct WatchProductImage: View {
    @EnvironmentObject var store: HealthStore
    var size: CGFloat = 230

    var body: some View {
        ZStack {
            // 上表带
            strap(top: true)
            // 下表带
            strap(top: false)
            // 表壳（钛灰）
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x9EA3A8), Color(hex: 0x5B6066)],
                                     center: .topLeading, start: 0.2, end: 1.1))
                .frame(width: size * 0.62, height: size * 0.62)
            // 表圈（深色渐变）
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x2E3236), Color(hex: 0x111417)],
                                     center: .center, start: 0.5, end: 1.0))
                .frame(width: size * 0.545, height: size * 0.545)
                .overlay(Circle().stroke(Color(hex: 0x3A3F44), lineWidth: size * 0.008))
            // 表盘
            Circle()
                .fill(Color(hex: 0x0A0C0E))
                .frame(width: size * 0.485, height: size * 0.485)
            // 表盘内容：日期 + 四环 + 星期
            dialContent
                .frame(width: size * 0.44, height: size * 0.44)
            // 表冠（右侧）
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(LinearGradient(colors: [Color(hex: 0xD8DADD), Color(hex: 0x8E9296)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.035, height: size * 0.09)
                .offset(x: size * 0.315)
            // 侧键
            RoundedRectangle(cornerRadius: size * 0.012)
                .fill(Color(hex: 0x7C8085))
                .frame(width: size * 0.02, height: size * 0.055)
                .offset(x: size * 0.322, y: size * 0.10)
        }
        .frame(width: size * 0.7, height: size)
    }

    private func strap(top: Bool) -> some View {
        VStack(spacing: 0) {
            if top {
                strapBuckle
                strapBody
            } else {
                strapBody
                strapBuckle
            }
        }
        .offset(y: top ? -size * 0.16 : size * 0.16)
    }

    /// 表带主体（橙色氟橡胶，中央金属扣纹路）
    private var strapBody: some View {
        RoundedRectangle(cornerRadius: size * 0.045)
            .fill(LinearGradient(colors: [Color(hex: 0xE8792B), Color(hex: 0xC45E1A)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.30, height: size * 0.30)
            .overlay(
                HStack(spacing: size * 0.10) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: size * 0.055, height: size * 0.26)
                    }
                }
            )
    }

    /// 表耳连接段
    private var strapBuckle: some View {
        RoundedRectangle(cornerRadius: size * 0.02)
            .fill(LinearGradient(colors: [Color(hex: 0x8E9296), Color(hex: 0x5B6066)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.26, height: size * 0.045)
    }

    /// 表盘：四环（步数/消耗/锻炼/次数）+ 日期星期
    private var dialContent: some View {
        GeometryReader { geo in
            let s = geo.size.width
            VStack(spacing: s * 0.05) {
                Text("\(Calendar.current.component(.day, from: Date()))月\(Calendar.current.component(.month, from: Date()))日")
                    .font(.system(size: s * 0.085, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                HStack(spacing: s * 0.09) {
                    dialRing(store.stepProgress, color: Color(hex: 0x4CD964))
                    dialRing(store.calorieProgress, color: Color(hex: 0xFFCC00))
                    dialRing(store.exerciseProgress, color: Color(hex: 0xFF3B30))
                    dialRing(store.workoutsProgress, color: Color(hex: 0x3478F6))
                }
                Text(weekdayText)
                    .font(.system(size: s * 0.085, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var weekdayText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        return f.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
    }

    private func dialRing(_ ratio: Double, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.9), lineWidth: 5.5)
            if ratio > 0.01 {
                Circle()
                    .trim(from: 0, to: min(ratio, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
