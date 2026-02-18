import SwiftUI
import Charts

struct SleepTimelineChart: View {
    let recording: SleepRecording

    var body: some View {
        if recording.decibelSamples.isEmpty {
            ContentUnavailableView(
                String(localized: "No Data"),
                systemImage: "chart.xyaxis.line",
                description: Text(String(localized: "No audio data available"))
            )
        } else {
            Chart {
                ForEach(Array(recording.decibelSamples.enumerated()), id: \.offset) { index, sample in
                    let timeInHours = Double(index) / 3600.0
                    AreaMark(
                        x: .value("Time", timeInHours),
                        y: .value("dB", sample)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.green.opacity(0.3), .yellow.opacity(0.3), .red.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", timeInHours),
                        y: .value("dB", sample)
                    )
                    .foregroundStyle(.purple.opacity(0.6))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            let startHour = Calendar.current.component(.hour, from: recording.date)
                            let displayHour = (startHour + Int(hours)) % 24
                            Text(formatHour(displayHour))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour) \(period)"
    }
}
