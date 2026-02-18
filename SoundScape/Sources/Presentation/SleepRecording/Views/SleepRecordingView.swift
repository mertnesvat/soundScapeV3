import SwiftUI

struct SleepRecordingView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    var body: some View {
        NavigationStack {
            Group {
                switch sleepRecordingService.status {
                case .idle:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        RecordingHistoryView()
                    }
                case .recording:
                    RecordingControlsView()
                case .analyzing:
                    analyzingView
                case .complete:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        RecordingHistoryView()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Sleep Recording"))
            .sheet(item: Binding(
                get: { sleepRecordingService.status == .complete ? sleepRecordingService.currentRecording : nil },
                set: { _ in sleepRecordingService.resetStatus() }
            )) { recording in
                NavigationStack {
                    SleepReportView(recording: recording)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            ContentUnavailableView(
                String(localized: "No Recordings"),
                systemImage: "mic.fill",
                description: Text(String(localized: "Tap the record button to capture your sleep sounds and discover snoring patterns"))
            )

            recordButton
                .padding(.bottom, 40)

            Spacer()
        }
    }

    // MARK: - Analyzing State

    private var analyzingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "Analyzing your sleep..."))
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            Task {
                let granted = await sleepRecordingService.requestMicrophonePermission()
                if granted {
                    sleepRecordingService.startRecording()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 80, height: 80)
                    .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    SleepRecordingView()
        .environment(SleepRecordingService())
        .preferredColorScheme(.dark)
}
