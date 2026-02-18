import SwiftUI

struct RecordingHistoryView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    let onSelectRecording: (SleepRecording) -> Void
    let onStartRecording: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var recordingToDelete: SleepRecording?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(groupedRecordings, id: \.key) { month, recordings in
                    Section(header: Text(month)) {
                        ForEach(recordings) { recording in
                            RecordingRowView(recording: recording)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelectRecording(recording)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        recordingToDelete = recording
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                // Storage info
                Section {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.secondary)
                        Text(String(localized: "\(sleepRecordingService.recordings.count) recordings"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(sleepRecordingService.formattedStorageUsed)
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)

            // Floating record button
            Button(action: onStartRecording) {
                ZStack {
                    Circle()
                        .fill(.purple)
                        .frame(width: 60, height: 60)
                        .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .alert(String(localized: "Delete Recording?"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let recording = recordingToDelete {
                    sleepRecordingService.deleteRecording(recording)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "The audio file will be permanently removed."))
        }
    }

    private var groupedRecordings: [(key: String, value: [SleepRecording])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sleepRecordingService.recordings) { recording in
            formatter.string(from: recording.date)
        }

        return grouped.sorted { $0.value[0].date > $1.value[0].date }
    }
}

// MARK: - Recording Row

struct RecordingRowView: View {
    let recording: SleepRecording

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayDateString)
                    .font(.headline)
                Text(recording.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Duration
            Text(recording.formattedDuration)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Snore score badge
            ZStack {
                Circle()
                    .fill(recording.snoreScoreCategoryColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("\(recording.snoreScore)")
                    .font(.caption.bold())
                    .foregroundStyle(recording.snoreScoreCategoryColor)
            }

            // Event count
            HStack(spacing: 2) {
                Image(systemName: "waveform")
                    .font(.caption2)
                Text("\(recording.eventCount)")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: recording.date)
    }
}
