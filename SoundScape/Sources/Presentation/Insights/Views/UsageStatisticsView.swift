import SwiftUI

struct UsageStatisticsView: View {
    let totalSessions: Int
    let totalSleepTime: TimeInterval

    private var formattedTotalTime: String {
        let totalHours = Int(totalSleepTime / 3600)
        if totalHours >= 24 {
            let days = totalHours / 24
            let remainingHours = totalHours % 24
            return "\(days)d \(remainingHours)h"
        }
        return "\(totalHours)h"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.purple)
                Text("Usage Statistics")
                    .font(.headline)
            }

            HStack(spacing: 16) {
                StatisticItemView(
                    value: "\(totalSessions)",
                    label: "Total Sessions",
                    icon: "moon.stars.fill"
                )

                Divider()
                    .frame(height: 50)

                StatisticItemView(
                    value: formattedTotalTime,
                    label: "Total Sleep Time",
                    icon: "bed.double.fill"
                )

                if totalSessions > 0 {
                    Divider()
                        .frame(height: 50)

                    StatisticItemView(
                        value: String(format: "%.1fh", (totalSleepTime / 3600) / Double(totalSessions)),
                        label: "Avg Per Session",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatisticItemView: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UsageStatisticsView(
        totalSessions: 45,
        totalSleepTime: 315 * 3600  // 315 hours
    )
    .padding()
    .preferredColorScheme(.dark)
}
