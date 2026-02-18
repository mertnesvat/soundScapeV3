import SwiftUI

struct SleepRecordingView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(SleepTimerService.self) private var sleepTimerService

    @State private var showingReport = false
    @State private var selectedDelay: Int = 0

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

            if let remaining = sleepRecordingService.delayRemaining {
                // Delay countdown
                VStack(spacing: 16) {
                    Text(String(localized: "Recording starts in"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formatDelay(remaining))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                    Button(String(localized: "Cancel")) {
                        sleepRecordingService.cancelDelay()
                        selectedDelay = 0
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                ContentUnavailableView(
                    String(localized: "No Recordings"),
                    systemImage: "mic.fill",
                    description: Text(String(localized: "Tap the record button to capture your sleep sounds and discover snoring patterns"))
                )

                // Delay picker
                delayPicker

                recordButtonLarge
            }

            Spacer()
        }
        .padding(.bottom, 48)
    }

    private var delayPicker: some View {
        VStack(spacing: 8) {
            Text(String(localized: "Delay Start"))
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    delayChip(label: String(localized: "None"), minutes: 0)
                    delayChip(label: String(localized: "15 min"), minutes: 15)
                    delayChip(label: String(localized: "30 min"), minutes: 30)
                    delayChip(label: String(localized: "45 min"), minutes: 45)
                    delayChip(label: String(localized: "1 hour"), minutes: 60)
                    delayChip(label: String(localized: "1.5 hr"), minutes: 90)
                    delayChip(label: String(localized: "2 hours"), minutes: 120)

                    if sleepTimerService.isActive {
                        delayChip(label: String(localized: "When sounds stop"), minutes: -1)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func delayChip(label: String, minutes: Int) -> some View {
        Button {
            selectedDelay = minutes
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedDelay == minutes ? Color.purple : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(Color.purple.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func formatDelay(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
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

        if selectedDelay == -1 {
            // Start when sleep timer ends
            sleepRecordingService.startRecordingWhenTimerEnds(sleepTimerService: sleepTimerService)
        } else if selectedDelay > 0 {
            sleepRecordingService.startRecordingWithDelay(minutes: selectedDelay)
        } else {
            sleepRecordingService.startRecording()
        }
    }
}
