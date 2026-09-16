import SwiftUI

struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    let isPositiveTrend: Bool?

    init(title: String, value: String, icon: String, color: Color, trend: String? = nil, isPositiveTrend: Bool? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.isPositiveTrend = isPositiveTrend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend, let isPositive = isPositiveTrend {
                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(trend)
                            .font(.caption)
                    }
                    .foregroundColor(isPositive ? .green : .red)
                }
            }

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
