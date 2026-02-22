import SwiftUI

struct SleepTimelineChart: View {
    let recording: SleepRecording
    @State private var selectedIndex: Int?

    /// Maximum number of points to render in the chart path.
    /// Keeps the Path lightweight even for 8+ hour recordings.
    private static let maxDisplayPoints = 300

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
                let displaySamples = Self.downsample(recording.decibelSamples, to: Self.maxDisplayPoints)
                let maxDB = displaySamples.max() ?? 1

                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(1, displaySamples.count - 1))

                    ZStack(alignment: .bottomLeading) {
                        // Area chart
                        areaPath(samples: displaySamples, maxDB: maxDB, width: width, height: height, stepX: stepX)
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.3), .yellow.opacity(0.3), .red.opacity(0.3)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )

                        // Line on top
                        linePath(samples: displaySamples, maxDB: maxDB, height: height, stepX: stepX)
                            .stroke(Color.purple, lineWidth: 1.5)

                        // Event markers
                        eventMarkers(displayCount: displaySamples.count, maxDB: maxDB, width: width, height: height)

                        // Selection indicator
                        if let index = selectedIndex, index < displaySamples.count {
                            selectionOverlay(
                                index: index,
                                sample: displaySamples[index],
                                maxDB: maxDB,
                                stepX: stepX,
                                width: width,
                                height: height
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let index = Int(value.location.x / stepX)
                                selectedIndex = max(0, min(index, displaySamples.count - 1))
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

    // MARK: - Path Builders

    private func areaPath(samples: [Float], maxDB: Float, width: CGFloat, height: CGFloat, stepX: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height))
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * stepX
                let y = height - CGFloat(sample / maxDB) * height
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
    }

    private func linePath(samples: [Float], maxDB: Float, height: CGFloat, stepX: CGFloat) -> Path {
        Path { path in
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * stepX
                let y = height - CGFloat(sample / maxDB) * height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    // MARK: - Event Markers

    private func eventMarkers(displayCount: Int, maxDB: Float, width: CGFloat, height: CGFloat) -> some View {
        let totalSamples = recording.decibelSamples.count
        let stepX = width / CGFloat(max(1, displayCount - 1))
        let ratio = totalSamples > 1 ? CGFloat(displayCount - 1) / CGFloat(totalSamples - 1) : 1

        return ForEach(recording.events.filter { $0.type != .silence }) { event in
            let eventIndex = Int(event.timestamp)
            if eventIndex < totalSamples {
                let displayX = CGFloat(eventIndex) * ratio * stepX
                let db = recording.decibelSamples[eventIndex]

                Circle()
                    .fill(event.type.color)
                    .frame(width: 6, height: 6)
                    .position(
                        x: displayX,
                        y: height - CGFloat(db / maxDB) * height
                    )
            }
        }
    }

    // MARK: - Selection Overlay

    @ViewBuilder
    private func selectionOverlay(index: Int, sample: Float, maxDB: Float, stepX: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let x = CGFloat(index) * stepX

        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 1, height: height)
            .position(x: x, y: height / 2)

        VStack(spacing: 2) {
            Text(timeLabel(forDisplayIndex: index))
                .font(.caption2)
            Text("\(Int(sample)) dB")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .position(x: min(max(x, 40), width - 40), y: 20)
    }

    // MARK: - Downsampling

    /// Reduces sample count by averaging buckets.
    /// If the input is already small enough, returns it unchanged.
    static func downsample(_ samples: [Float], to maxPoints: Int) -> [Float] {
        guard samples.count > maxPoints else { return samples }

        let bucketSize = Double(samples.count) / Double(maxPoints)
        var result = [Float]()
        result.reserveCapacity(maxPoints)

        for i in 0..<maxPoints {
            let start = Int(Double(i) * bucketSize)
            let end = min(Int(Double(i + 1) * bucketSize), samples.count)
            guard start < end else { continue }

            var sum: Float = 0
            for j in start..<end {
                sum += samples[j]
            }
            result.append(sum / Float(end - start))
        }

        return result
    }

    // MARK: - Helpers

    /// Maps a display-point index back to a time offset in the original recording.
    private func timeLabel(forDisplayIndex displayIndex: Int) -> String {
        let totalSamples = recording.decibelSamples.count
        let displayCount = min(totalSamples, Self.maxDisplayPoints)
        let ratio = totalSamples > 1 ? Double(totalSamples - 1) / Double(max(1, displayCount - 1)) : 1
        let originalIndex = Int(Double(displayIndex) * ratio)
        let secondsFromStart = TimeInterval(min(originalIndex, totalSamples - 1))
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
