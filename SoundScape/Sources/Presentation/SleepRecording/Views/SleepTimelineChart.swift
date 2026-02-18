import Charts
import SwiftUI

struct SleepTimelineChart: View {
    let recording: SleepRecording

    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let selectedIndex = selectedIndex, selectedIndex < recording.decibelSamples.count {
                let time = timeLabel(for: selectedIndex)
                let db = Int(recording.decibelSamples[selectedIndex])
                Text("\(time) \u{00B7} \(db) dB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Chart {
                ForEach(Array(recording.decibelSamples.enumerated()), id: \.offset) { index, value in
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("dB", value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.green.opacity(0.6), .yellow.opacity(0.6), .red.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Event markers
                ForEach(recording.events.filter { $0.type != .silence }) { event in
                    let index = Int(event.timestamp)
                    if index < recording.decibelSamples.count {
                        PointMark(
                            x: .value("Time", index),
                            y: .value("dB", recording.decibelSamples[index])
                        )
                        .foregroundStyle(event.type.color)
                        .symbolSize(30)
                    }
                }

                // Selection rule mark
                if let selectedIndex = selectedIndex {
                    RuleMark(x: .value("Time", selectedIndex))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 3600)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let seconds = value.as(Int.self) {
                            Text(timeLabel(for: seconds))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let db = value.as(Double.self) {
                            Text("\(Int(db))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    if let index: Int = proxy.value(atX: x) {
                                        selectedIndex = max(0, min(recording.decibelSamples.count - 1, index))
                                    }
                                }
                                .onEnded { _ in
                                    selectedIndex = nil
                                }
                        )
                }
            }
        }
    }

    private func timeLabel(for secondsFromStart: Int) -> String {
        let date = recording.date.addingTimeInterval(TimeInterval(secondsFromStart))
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}
