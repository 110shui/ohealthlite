import SwiftUI

/// 首页指标卡通用容器
struct MetricCard<Chart: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let sub: String
    @ViewBuilder var chart: Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.oppo(14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.oppo(28, weight: .bold))
                Text(unit).font(.oppo(12)).foregroundColor(.secondary)
            }
            Text(sub).font(.oppo(12)).foregroundColor(.secondary)
            chart
                .frame(height: 40)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
