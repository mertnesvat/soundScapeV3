import SwiftUI

struct MetricsGridView: View {
    let averageDuration: TimeInterval
    let averageQuality: Int
    let averageTimeToSleep: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.purple)
                Text("Key Metrics")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCardView(
                    title: "Avg Duration",
                    value: formatDuration(averageDuration),
                    icon: "bed.double.fill",
                    color: .blue
                )

                MetricCardView(
                    title: "Sleep Quality",
                    value: "\(averageQuality)%",
                    icon: "star.fill",
                    color: qualityColor
                )

                MetricCardView(
                    title: "Time to Sleep",
                    value: formatTimeToSleep(averageTimeToSleep),
                    icon: "moon.zzz.fill",
                    color: .indigo
                )
            }
        }
    }

    private var qualityColor: Color {
        if averageQuality >= 80 { return .green }
        if averageQuality >= 60 { return .yellow }
        return .orange
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatTimeToSleep(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        return "\(hours)h \(remainingMins)m"
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MetricsGridView(
        averageDuration: 7.5 * 3600,
        averageQuality: 82,
        averageTimeToSleep: 15 * 60
    )
    .padding()
    .preferredColorScheme(.dark)
}
