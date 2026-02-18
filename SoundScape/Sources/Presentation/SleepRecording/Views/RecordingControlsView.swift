import SwiftUI

struct RecordingControlsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(AudioEngine.self) private var audioEngine
    @State private var showStopConfirmation = false
    @State private var showPermissionAlert = false
    @State private var showSoundWarning = false
    @State private var selectedDelay: Int = 0
    @State private var stopSoundsBeforeRecording = false

    private let delayOptions = [0, 15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Sound playback warning
            if audioEngine.isAnyPlaying && sleepRecordingService.status == .idle && !sleepRecordingService.isDelayActive {
                soundPlaybackWarning
            }

            // Instructional text
            if sleepRecordingService.status == .idle && !sleepRecordingService.isDelayActive && !audioEngine.isAnyPlaying {
                Text(String(localized: "Place your phone on the nightstand with the microphone facing you"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Delay countdown
            if sleepRecordingService.isDelayActive, let remaining = sleepRecordingService.delayRemaining {
                VStack(spacing: 12) {
                    if sleepRecordingService.shouldStopSoundsOnRecordingStart {
                        Text(String(localized: "Sounds will stop & recording begins in"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(String(localized: "Recording starts in"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatDuration(remaining))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.purple)

                    Button {
                        sleepRecordingService.cancelDelay()
                    } label: {
                        Text(String(localized: "Cancel"))
                            .font(.headline)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
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

            // Record button with pulsing rings (hidden during delay)
            if !sleepRecordingService.isDelayActive {
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
            }

            if !sleepRecordingService.isDelayActive {
                Text(sleepRecordingService.status == .recording
                     ? String(localized: "Stop Recording")
                     : String(localized: "Start Recording"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Delay picker (only when idle and not already delaying)
            if sleepRecordingService.status == .idle && !sleepRecordingService.isDelayActive {
                VStack(spacing: 8) {
                    Text(audioEngine.isAnyPlaying
                         ? String(localized: "Wind-down Timer")
                         : String(localized: "Delay Start"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(delayOptions, id: \.self) { minutes in
                                Button {
                                    selectedDelay = minutes
                                    if minutes == 0 {
                                        stopSoundsBeforeRecording = false
                                    }
                                } label: {
                                    Text(delayLabel(minutes))
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedDelay == minutes ? Color.purple : Color(.secondarySystemGroupedBackground))
                                        .foregroundStyle(selectedDelay == minutes ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Stop sounds toggle (only when sounds are playing and delay > 0)
                    if audioEngine.isAnyPlaying && selectedDelay > 0 {
                        Toggle(isOn: $stopSoundsBeforeRecording) {
                            Label(String(localized: "Stop sounds when recording starts"), systemImage: "speaker.slash.fill")
                                .font(.caption)
                        }
                        .toggleStyle(.switch)
                        .tint(.purple)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            }

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
        .confirmationDialog(
            String(localized: "Sounds Are Playing"),
            isPresented: $showSoundWarning,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Stop Sounds & Record")) {
                audioEngine.stopAll()
                startRecordingFlow()
            }
            Button(String(localized: "Record Anyway")) {
                startRecordingFlow()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Playing sounds through the speaker can interfere with snore detection. For best results, stop sounds before recording."))
        }
    }

    // MARK: - Sound Warning

    private var soundPlaybackWarning: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.orange)
                Text(String(localized: "Sounds are playing"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Text(String(localized: "Sound playback may interfere with snore detection accuracy. Use the wind-down timer to stop sounds automatically, or stop them before recording."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var decibelScale: Float {
        let normalized = sleepRecordingService.currentDecibels / 100.0
        return min(1.5, max(0.8, 0.8 + normalized * 0.7))
    }

    private func handleButtonTap() {
        if sleepRecordingService.isDelayActive {
            sleepRecordingService.cancelDelay()
        } else if sleepRecordingService.status == .recording {
            showStopConfirmation = true
        } else {
            // If sounds are playing and no delay set, show warning
            if audioEngine.isAnyPlaying && selectedDelay == 0 {
                showSoundWarning = true
            } else {
                startRecordingFlow()
            }
        }
    }

    private func startRecordingFlow() {
        Task {
            let granted = await sleepRecordingService.requestMicrophonePermission()
            if granted {
                if selectedDelay > 0 {
                    sleepRecordingService.startRecordingWithDelay(
                        minutes: selectedDelay,
                        stopSoundsFirst: stopSoundsBeforeRecording
                    )
                } else {
                    sleepRecordingService.startRecording()
                }
            } else {
                showPermissionAlert = true
            }
        }
    }

    private func delayLabel(_ minutes: Int) -> String {
        if minutes == 0 { return String(localized: "None") }
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        if remaining == 0 { return "\(hours)h" }
        return "\(hours)h \(remaining)m"
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
            .environment(AudioEngine())
    }
    .preferredColorScheme(.dark)
}
