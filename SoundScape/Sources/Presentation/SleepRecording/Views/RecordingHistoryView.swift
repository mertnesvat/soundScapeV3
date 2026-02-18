import SwiftUI

struct RecordingHistoryView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var selectedRecording: SleepRecording?
    @State private var showDeleteConfirmation = false
    @State private var recordingToDelete: SleepRecording?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(groupedRecordings, id: \.key) { month, recordings in
                    Section {
                        ForEach(recordings) { recording in
                            recordingRow(recording)
                                .contentShape(Rectangle())
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
                    } header: {
                        Text(month)
                    }
                }

                // Storage info
                Section {
                    HStack {
                        Text(String(localized: "\(sleepRecordingService.recordings.count) recordings"))
                        Spacer()
                        Text(sleepRecordingService.formattedStorageUsed)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)

            // Floating record button
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
                        .frame(width: 60, height: 60)
                        .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedRecording) { recording in
            NavigationStack {
                SleepReportView(recording: recording)
            }
        }
        .alert(String(localized: "Delete Recording?"), isPresented: $showDeleteConfirmation) {
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

    // MARK: - Grouped Recordings

    private var groupedRecordings: [(key: String, value: [SleepRecording])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sleepRecordingService.recordings) { recording in
            formatter.string(from: recording.date)
        }

        return grouped.sorted { $0.value.first?.date ?? Date() > $1.value.first?.date ?? Date() }
    }

    // MARK: - Recording Row

    private func recordingRow(_ recording: SleepRecording) -> some View {
        HStack(spacing: 12) {
            // Snore score badge
            ZStack {
                Circle()
                    .fill(recording.snoreScoreCategory.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text("\(recording.snoreScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(recording.snoreScoreCategory.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.formattedDate)
                    .font(.headline)

                Text(recording.formattedTimeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(recording.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text("\(recording.eventCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RecordingHistoryView()
            .environment(SleepRecordingService())
    }
    .preferredColorScheme(.dark)
}
