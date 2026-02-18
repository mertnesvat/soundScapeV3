import SwiftUI

struct RecordingHistoryView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    @State private var selectedRecording: SleepRecording?
    @State private var recordingToDelete: SleepRecording?
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            ForEach(sleepRecordingService.recordings) { recording in
                recordingRow(recording)
                    .onTapGesture {
                        selectedRecording = recording
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            recordingToDelete = recording
                            showDeleteConfirmation = true
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                    }
            }

            // Storage info
            Section {
                HStack {
                    Spacer()
                    Text(String(localized: "\(sleepRecordingService.recordings.count) recordings · \(sleepRecordingService.formattedStorageUsed) used"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .sheet(item: $selectedRecording) { recording in
            SleepReportView(recording: recording)
        }
        .alert(String(localized: "Delete Recording"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) {
                recordingToDelete = nil
            }
            Button(String(localized: "Delete"), role: .destructive) {
                if let recording = recordingToDelete {
                    sleepRecordingService.deleteRecording(recording)
                }
                recordingToDelete = nil
            }
        } message: {
            Text(String(localized: "Delete this recording? The audio file will be permanently removed."))
        }
    }

    private func recordingRow(_ recording: SleepRecording) -> some View {
        HStack(spacing: 12) {
            // Snore score badge
            ZStack {
                Circle()
                    .fill(scoreColor(for: recording.snoreScore))
                    .frame(width: 40, height: 40)
                Text("\(recording.snoreScore)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.formattedDate)
                    .font(.subheadline.bold())
                Text(recording.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(recording.formattedDuration)
                    .font(.subheadline)
                Text(String(localized: "\(recording.eventCount) events"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 0...30: return .green
        case 31...60: return .yellow
        default: return .red
        }
    }
}
