import SwiftUI

struct RecordingControlsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructional text
            Text(String(localized: "Recording in progress..."))
                .font(.headline)
                .foregroundStyle(.secondary)

            // Elapsed time
            Text(formattedDuration)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.white)

            // Current decibels
            Text(String(localized: "\(Int(sleepRecordingService.currentDecibels)) dB"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Animated record button
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(.red.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(80 + index * 20), height: CGFloat(80 + index * 20))
                        .scaleEffect(pulseScale(for: index))
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: sleepRecordingService.currentDecibels
                        )
                }

                // Stop button
                Button(action: onStop) {
                    Circle()
                        .fill(.red)
                        .frame(width: 80, height: 80)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        }
                }
            }
            .frame(height: 140)

            Text(String(localized: "Stop Recording"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var formattedDuration: String {
        let total = Int(sleepRecordingService.recordingDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func pulseScale(for index: Int) -> CGFloat {
        let normalizedDb = CGFloat(sleepRecordingService.currentDecibels) / 90.0
        let baseScale = 0.8 + normalizedDb * 0.7
        return min(1.5, max(0.8, baseScale + CGFloat(index) * 0.05))
    }
}
