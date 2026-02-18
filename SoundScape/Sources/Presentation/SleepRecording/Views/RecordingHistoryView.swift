import SwiftUI

struct RecordingHistoryView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(AudioEngine.self) private var audioEngine
    @State private var selectedRecording: SleepRecording?
    @State private var showDeleteConfirmation = false
    @State private var recordingToDelete: SleepRecording?
    @State private var showSoundRecordingOptions = false
    @State private var exportText: String = ""

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: generateCombinedReport()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(sleepRecordingService.recordings.isEmpty)
                }
            }

            // Floating record button
            Button {
                if audioEngine.isAnyPlaying {
                    showSoundRecordingOptions = true
                } else {
                    Task {
                        let granted = await sleepRecordingService.requestMicrophonePermission()
                        if granted {
                            sleepRecordingService.startRecording()
                        }
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
            .padding(.bottom, audioEngine.activeSounds.isEmpty ? 20 : 88)
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
        .sheet(isPresented: $showSoundRecordingOptions) {
            SoundAwareRecordingSheet()
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

    // MARK: - Export

    private func generateCombinedReport() -> String {
        var report = "SoundScape Sleep Report - All Recordings\n"
        report += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n"
        report += "Total recordings: \(sleepRecordingService.recordings.count)\n"
        report += String(repeating: "=", count: 50) + "\n\n"

        for recording in sleepRecordingService.recordings {
            report += "Date: \(recording.formattedDate)\n"
            report += "Time: \(recording.formattedTimeRange)\n"
            report += "Duration: \(recording.formattedDuration)\n"
            report += "Snore Score: \(recording.snoreScore)/100 (\(recording.snoreScoreCategory.displayName))\n"
            report += "Snoring: \(String(format: "%.0f", recording.snoringMinutes)) min | Events: \(recording.eventCount) | Peak: \(Int(recording.peakDecibels)) dB\n"
            report += String(repeating: "-", count: 30) + "\n"

            for event in recording.events.filter({ $0.type != .silence }) {
                report += "  \(event.formattedTimestamp) - \(event.type.displayName) (\(event.formattedDuration), \(Int(event.peakDecibels)) dB)\n"
            }
            report += "\n"
        }

        report += "\nNote: This report was generated by SoundScape and is not a medical diagnosis.\n"
        return report
    }
}

#Preview {
    NavigationStack {
        RecordingHistoryView()
            .environment(SleepRecordingService())
            .environment(AudioEngine())
    }
    .preferredColorScheme(.dark)
}
