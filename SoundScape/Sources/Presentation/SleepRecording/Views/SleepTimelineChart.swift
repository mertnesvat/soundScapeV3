import SwiftUI

struct SleepTimelineChart: View {
    let recording: SleepRecording
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Sound Timeline"))
                .font(.headline)

            if recording.decibelSamples.isEmpty {
                Text(String(localized: "No data available"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    let maxDB = recording.decibelSamples.max() ?? 1
                    let width = geometry.size.width
                    let height = geometry.size.height

                    ZStack(alignment: .bottomLeading) {
                        // Area chart
                        Path { path in
                            let stepX = width / CGFloat(max(1, recording.decibelSamples.count - 1))

                            path.move(to: CGPoint(x: 0, y: height))

                            for (index, sample) in recording.decibelSamples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalizedY = CGFloat(sample / maxDB)
                                let y = height - (normalizedY * height)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }

                            path.addLine(to: CGPoint(x: width, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .yellow.opacity(0.3), .red.opacity(0.3)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )

                        // Line on top
                        Path { path in
                            let stepX = width / CGFloat(max(1, recording.decibelSamples.count - 1))

                            for (index, sample) in recording.decibelSamples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalizedY = CGFloat(sample / maxDB)
                                let y = height - (normalizedY * height)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.purple, lineWidth: 1.5)

                        // Event markers
                        ForEach(recording.events.filter { $0.type != .silence }) { event in
                            let eventIndex = Int(event.timestamp)
                            if eventIndex < recording.decibelSamples.count {
                                let stepX = width / CGFloat(max(1, recording.decibelSamples.count - 1))
                                let x = CGFloat(eventIndex) * stepX

                                Circle()
                                    .fill(event.type.color)
                                    .frame(width: 6, height: 6)
                                    .position(
                                        x: x,
                                        y: height - CGFloat(recording.decibelSamples[eventIndex] / maxDB) * height
                                    )
                            }
                        }

                        // Selection indicator
                        if let index = selectedIndex, index < recording.decibelSamples.count {
                            let stepX = width / CGFloat(max(1, recording.decibelSamples.count - 1))
                            let x = CGFloat(index) * stepX

                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: height)
                                .position(x: x, y: height / 2)

                            VStack(spacing: 2) {
                                Text(timeLabel(for: index))
                                    .font(.caption2)
                                Text("\(Int(recording.decibelSamples[index])) dB")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(4)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .position(x: min(max(x, 40), width - 40), y: 20)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let stepX = width / CGFloat(max(1, recording.decibelSamples.count - 1))
                                let index = Int(value.location.x / stepX)
                                selectedIndex = max(0, min(index, recording.decibelSamples.count - 1))
                            }
                            .onEnded { _ in
                                selectedIndex = nil
                            }
                    )
                }

                // Time axis labels
                HStack {
                    ForEach(timeAxisLabels(), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if label != timeAxisLabels().last {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func timeLabel(for sampleIndex: Int) -> String {
        let secondsFromStart = TimeInterval(sampleIndex)
        let date = recording.date.addingTimeInterval(secondsFromStart)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func timeAxisLabels() -> [String] {
        let totalSamples = recording.decibelSamples.count
        guard totalSamples > 0 else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        let labelCount = min(5, totalSamples)
        let step = totalSamples / max(1, labelCount - 1)

        var labels: [String] = []
        for i in 0..<labelCount {
            let index = min(i * step, totalSamples - 1)
            let date = recording.date.addingTimeInterval(TimeInterval(index))
            labels.append(formatter.string(from: date))
        }

        return labels
    }
}

#Preview {
    SleepTimelineChart(recording: SleepRecording(
        date: Date().addingTimeInterval(-28800),
        endDate: Date(),
        duration: 100,
        decibelSamples: (0..<100).map { _ in Float.random(in: 25...65) },
        averageDecibels: 35,
        peakDecibels: 65,
        snoreScore: 45
    ))
    .frame(height: 200)
    .padding()
    .preferredColorScheme(.dark)
}
