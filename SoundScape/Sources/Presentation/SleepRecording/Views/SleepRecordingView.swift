import SwiftUI

struct SleepRecordingView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    @State private var showingReport = false

    var body: some View {
        NavigationStack {
            ZStack {
                switch sleepRecordingService.status {
                case .idle:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        recordingHistoryPlaceholder
                    }
                case .recording:
                    RecordingControlsView()
                case .analyzing:
                    analyzingView
                case .complete:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        recordingHistoryPlaceholder
                    }
                }

                // Floating record button when showing history
                if sleepRecordingService.status == .idle && !sleepRecordingService.recordings.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            recordButton
                                .padding(.trailing, 24)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Sleep Recording"))
            .sheet(isPresented: $showingReport) {
                if let recording = sleepRecordingService.currentRecording {
                    SleepReportView(recording: recording)
                }
            }
            .onChange(of: sleepRecordingService.status) { _, newStatus in
                if newStatus == .complete {
                    showingReport = true
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ContentUnavailableView(
                String(localized: "No Recordings"),
                systemImage: "mic.fill",
                description: Text(String(localized: "Tap the record button to capture your sleep sounds and discover snoring patterns"))
            )

            recordButtonLarge
                .padding(.bottom, 48)

            Spacer()
        }
    }

    // MARK: - History Placeholder

    private var recordingHistoryPlaceholder: some View {
        RecordingHistoryView()
    }

    // MARK: - Analyzing State

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            Text(String(localized: "Analyzing your sleep..."))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Record Buttons

    private var recordButtonLarge: some View {
        Button {
            Task {
                await startRecording()
            }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.purple)
                        .frame(width: 80, height: 80)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }

                Text(String(localized: "Start Recording"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var recordButton: some View {
        Button {
            Task {
                await startRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 64, height: 64)
                    .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                Image(systemName: "mic.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    @MainActor
    private func startRecording() async {
        if !sleepRecordingService.microphonePermissionGranted {
            let granted = await sleepRecordingService.requestMicrophonePermission()
            guard granted else { return }
        }
        sleepRecordingService.startRecording()
    }
}
