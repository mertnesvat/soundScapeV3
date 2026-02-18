import SwiftUI

struct RecordingControlsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var showStopConfirmation = false
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructional text
            if sleepRecordingService.status == .idle {
                Text(String(localized: "Place your phone on the nightstand with the microphone facing you"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Elapsed time
            if sleepRecordingService.status == .recording {
                Text(formatDuration(sleepRecordingService.recordingDuration))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)

                Text("\(Int(sleepRecordingService.currentDecibels)) dB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Record button with pulsing rings
            ZStack {
                if sleepRecordingService.status == .recording {
                    // Pulsing rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.red.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                            .frame(
                                width: 80 + CGFloat(index + 1) * 20 * CGFloat(decibelScale),
                                height: 80 + CGFloat(index + 1) * 20 * CGFloat(decibelScale)
                            )
                            .animation(.easeInOut(duration: 0.3), value: sleepRecordingService.currentDecibels)
                    }
                }

                Button {
                    handleButtonTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(sleepRecordingService.status == .recording ? .red : .purple)
                            .frame(width: 80, height: 80)
                            .shadow(
                                color: (sleepRecordingService.status == .recording ? Color.red : Color.purple).opacity(0.4),
                                radius: 12, y: 4
                            )

                        Image(systemName: sleepRecordingService.status == .recording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 160)

            Text(sleepRecordingService.status == .recording
                 ? String(localized: "Stop Recording")
                 : String(localized: "Start Recording"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .alert(String(localized: "Stop Recording?"), isPresented: $showStopConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Stop & Analyze"), role: .destructive) {
                sleepRecordingService.stopRecording()
            }
        } message: {
            Text(String(localized: "Stop recording and analyze your sleep?"))
        }
        .alert(String(localized: "Microphone Access Required"), isPresented: $showPermissionAlert) {
            Button(String(localized: "Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "SoundScape needs microphone access to record your sleep. Please enable it in Settings."))
        }
    }

    // MARK: - Helpers

    private var decibelScale: Float {
        let normalized = sleepRecordingService.currentDecibels / 100.0
        return min(1.5, max(0.8, 0.8 + normalized * 0.7))
    }

    private func handleButtonTap() {
        if sleepRecordingService.status == .recording {
            showStopConfirmation = true
        } else {
            Task {
                let granted = await sleepRecordingService.requestMicrophonePermission()
                if granted {
                    sleepRecordingService.startRecording()
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RecordingControlsView()
            .environment(SleepRecordingService())
    }
    .preferredColorScheme(.dark)
}
