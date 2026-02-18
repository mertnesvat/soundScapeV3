import SwiftUI

struct RecordingControlsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    @State private var showStopConfirmation = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Instructional text
            if sleepRecordingService.status == .idle {
                Text(String(localized: "Place your phone on the nightstand with the microphone facing you"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Elapsed time
            if sleepRecordingService.status == .recording {
                VStack(spacing: 4) {
                    Text(formattedElapsedTime)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(String(localized: "\(Int(sleepRecordingService.currentDecibels)) dB"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Record/Stop button with pulsing rings
            ZStack {
                if sleepRecordingService.status == .recording {
                    pulsingRings
                }

                Button {
                    if sleepRecordingService.status == .recording {
                        showStopConfirmation = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(sleepRecordingService.status == .recording ? .red : .purple)
                            .frame(width: 80, height: 80)

                        Image(systemName: sleepRecordingService.status == .recording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }

            Text(sleepRecordingService.status == .recording
                 ? String(localized: "Stop Recording")
                 : String(localized: "Start Recording"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .alert(String(localized: "Stop Recording"), isPresented: $showStopConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Stop & Analyze"), role: .destructive) {
                sleepRecordingService.stopRecording()
            }
        } message: {
            Text(String(localized: "Stop recording and analyze your sleep?"))
        }
    }

    // MARK: - Elapsed Time

    private var formattedElapsedTime: String {
        let total = Int(sleepRecordingService.recordingDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Pulsing Rings

    private var pulsingRings: some View {
        let scale = CGFloat(0.8 + Double(min(sleepRecordingService.currentDecibels, 80)) / 80.0 * 0.7)
        return ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.red.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                    .frame(width: 80 + CGFloat(i) * 30, height: 80 + CGFloat(i) * 30)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 0.3), value: scale)
            }
        }
    }
}
