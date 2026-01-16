import SwiftUI

struct SleepGoalView: View {
    let progress: Double
    let targetHours: Double
    let actualHours: Double

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.8 { return .yellow }
        return .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.purple)
                Text("Sleep Goal")
                    .font(.headline)
                Spacer()
                Text("\(progressPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(progressColor)
            }

            VStack(spacing: 12) {
                // Progress ring
                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: min(progress, 1.0))
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text(String(format: "%.1f", actualHours))
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("hrs")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(progressColor)
                                .frame(width: 8, height: 8)
                            Text("Average Sleep")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1fh", actualHours))
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text("Target")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1fh", targetHours))
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        if progress >= 1.0 {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Goal achieved!")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            let remaining = targetHours - actualHours
                            Text("Need \(String(format: "%.1f", max(0, remaining)))h more on average")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        SleepGoalView(
            progress: 0.85,
            targetHours: 8.0,
            actualHours: 6.8
        )

        SleepGoalView(
            progress: 1.05,
            targetHours: 8.0,
            actualHours: 8.4
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
