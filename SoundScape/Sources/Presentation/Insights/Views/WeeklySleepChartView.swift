import SwiftUI

struct WeeklySleepChartView: View {
    let data: [(day: String, hours: Double)]

    private var maxHours: Double {
        max(data.map { $0.hours }.max() ?? 8, 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                Text("Weekly Sleep Duration")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                // Chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 4) {
                            // Hours label
                            if item.hours > 0 {
                                Text(String(format: "%.1f", item.hours))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barGradient(for: item.hours))
                                .frame(height: barHeight(for: item.hours))
                                .frame(maxWidth: .infinity)

                            // Day label
                            Text(item.day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 180)

                // Reference lines
                HStack {
                    Text("Target: 8h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Avg: \(String(format: "%.1f", averageHours))h")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var averageHours: Double {
        let nonZero = data.filter { $0.hours > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.map { $0.hours }.reduce(0, +) / Double(nonZero.count)
    }

    private func barHeight(for hours: Double) -> CGFloat {
        guard maxHours > 0 else { return 0 }
        let percentage = hours / maxHours
        return max(4, CGFloat(percentage) * 140)
    }

    private func barGradient(for hours: Double) -> LinearGradient {
        let color: Color
        if hours >= 7 && hours <= 9 {
            color = .green
        } else if hours >= 6 {
            color = .yellow
        } else if hours > 0 {
            color = .orange
        } else {
            color = .gray.opacity(0.3)
        }

        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

#Preview {
    WeeklySleepChartView(data: [
        (day: "Mon", hours: 7.5),
        (day: "Tue", hours: 6.2),
        (day: "Wed", hours: 8.1),
        (day: "Thu", hours: 7.0),
        (day: "Fri", hours: 5.5),
        (day: "Sat", hours: 8.5),
        (day: "Sun", hours: 7.8)
    ])
    .padding()
    .preferredColorScheme(.dark)
}
