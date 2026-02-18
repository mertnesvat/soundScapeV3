import SwiftUI

struct SleepRecordingView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var showingPermissionAlert = false
    @State private var showingStopConfirmation = false
    @State private var showingReport = false
    @State private var selectedRecording: SleepRecording?

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    switch sleepRecordingService.status {
                    case .idle:
                        if sleepRecordingService.recordings.isEmpty {
                            emptyStateView
                        } else {
                            RecordingHistoryView(
                                onSelectRecording: { recording in
                                    selectedRecording = recording
                                },
                                onStartRecording: {
                                    Task { await handleStartRecording() }
                                }
                            )
                        }
                    case .recording:
                        RecordingControlsView(
                            onStop: { showingStopConfirmation = true }
                        )
                    case .analyzing:
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(String(localized: "Analyzing your sleep..."))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    case .complete:
                        emptyStateView
                    }
                }
            }
            .navigationTitle(String(localized: "Sleep Recording"))
            .sheet(item: $selectedRecording) { recording in
                SleepReportView(recording: recording)
            }
            .onChange(of: sleepRecordingService.status) { _, newStatus in
                if newStatus == .complete, let recording = sleepRecordingService.currentRecording {
                    selectedRecording = recording
                }
            }
            .alert(String(localized: "Microphone Access Required"), isPresented: $showingPermissionAlert) {
                Button(String(localized: "Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "SoundScape needs microphone access to record your sleep sounds. Please enable it in Settings."))
            }
            .alert(String(localized: "Stop Recording?"), isPresented: $showingStopConfirmation) {
                Button(String(localized: "Stop & Analyze"), role: .destructive) {
                    sleepRecordingService.stopRecording()
                }
                Button(String(localized: "Continue Recording"), role: .cancel) {}
            } message: {
                Text(String(localized: "Stop recording and analyze your sleep?"))
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            ContentUnavailableView(
                String(localized: "No Recordings"),
                systemImage: "mic.badge.waveform",
                description: Text(String(localized: "Tap the record button to capture your sleep sounds and discover snoring patterns"))
            )
            recordButton
            Spacer()
        }
    }

    private var recordButton: some View {
        Button {
            Task { await handleStartRecording() }
        } label: {
            ZStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 80, height: 80)
                Image(systemName: "mic.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
        }
        .padding(.bottom, 32)
    }

    private func handleStartRecording() async {
        let granted = await sleepRecordingService.requestMicrophonePermission()
        if granted {
            sleepRecordingService.startRecording()
        } else {
            showingPermissionAlert = true
        }
    }
}
