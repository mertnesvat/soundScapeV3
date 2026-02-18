import SwiftUI

struct SoundAwareRecordingSheet: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Int = 15
    private let timerOptions = [5, 10, 15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning header
                VStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                        .padding(.top, 8)

                    Text(String(localized: "Sounds Are Playing"))
                        .font(.title3.weight(.semibold))

                    Text(String(localized: "Sound playback through the speaker can interfere with snore detection. Choose how you'd like to proceed:"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Divider()

                // Option 1: Chain timer (play sounds for X min, then record)
                VStack(spacing: 12) {
                    Label(String(localized: "Play sounds, then record"), systemImage: "timer")
                        .font(.headline)

                    Text(String(localized: "Keep listening for a while, then sounds stop and recording begins automatically."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Time picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timerOptions, id: \.self) { minutes in
                                Button {
                                    selectedMinutes = minutes
                                } label: {
                                    Text(formatMinutes(minutes))
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedMinutes == minutes ? Color.purple : Color(.secondarySystemGroupedBackground))
                                        .foregroundStyle(selectedMinutes == minutes ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        startChainTimer()
                    } label: {
                        HStack {
                            Image(systemName: "moon.fill")
                            Text(String(localized: "Start Wind-down (\(formatMinutes(selectedMinutes)))"))
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Option 2: Stop sounds immediately and record
                Button {
                    stopAndRecord()
                } label: {
                    HStack {
                        Image(systemName: "speaker.slash.fill")
                        Text(String(localized: "Stop Sounds & Record Now"))
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                // Option 3: Record anyway
                Button {
                    recordAnyway()
                } label: {
                    Text(String(localized: "Record Anyway (sounds may affect accuracy)"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func startChainTimer() {
        dismiss()
        Task {
            let granted = await sleepRecordingService.requestMicrophonePermission()
            if granted {
                sleepRecordingService.startRecordingWithDelay(
                    minutes: selectedMinutes,
                    stopSoundsFirst: true
                )
            }
        }
    }

    private func stopAndRecord() {
        dismiss()
        audioEngine.stopAll()
        Task {
            let granted = await sleepRecordingService.requestMicrophonePermission()
            if granted {
                // Wait for audio fade-out before starting recorder
                try? await Task.sleep(for: .milliseconds(500))
                sleepRecordingService.startRecording()
            }
        }
    }

    private func recordAnyway() {
        dismiss()
        Task {
            let granted = await sleepRecordingService.requestMicrophonePermission()
            if granted {
                sleepRecordingService.startRecording()
            }
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        if remaining == 0 { return "\(hours)h" }
        return "\(hours)h \(remaining)m"
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            SoundAwareRecordingSheet()
                .environment(SleepRecordingService())
                .environment(AudioEngine())
        }
        .preferredColorScheme(.dark)
}
