import SwiftUI

struct SleepReportView: View {
    let recording: SleepRecording

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Snore Score
                    snoreScoreSection

                    // Summary Cards
                    summaryCardsSection

                    // Timeline placeholder
                    SleepTimelineChart(recording: recording)
                        .frame(height: 200)
                        .padding(.horizontal)

                    // Listen to Highlights button
                    if !recording.events.isEmpty {
                        NavigationLink {
                            AudioHighlightsView(recording: recording)
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text(String(localized: "Listen to Highlights"))
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    // Events list
                    eventsSection

                    // Medical disclaimer
                    disclaimerSection
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "Sleep Report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(
                        item: generateReportText(),
                        subject: Text(String(localized: "SoundScape Sleep Report")),
                        message: Text(String(localized: "My sleep report from \(recording.formattedDate)"))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text(recording.formattedDate + " · " + recording.formattedTimeRange)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Snore Score

    private var snoreScoreSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: CGFloat(recording.snoreScore) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(recording.snoreScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text(String(localized: "Snore Score"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(recording.snoreScoreCategory)
                .font(.headline)
                .foregroundStyle(scoreColor)
        }
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        switch recording.snoreScore {
        case 0...30: return .green
        case 31...60: return .yellow
        default: return .red
        }
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                summaryCard(icon: "clock.fill", value: recording.formattedDuration, label: String(localized: "Duration"))
                summaryCard(icon: "zzz", value: String(format: "%.0f min", recording.snoringMinutes), label: String(localized: "Snoring"))
                summaryCard(icon: "list.bullet", value: "\(recording.eventCount)", label: String(localized: "Events"))
                summaryCard(icon: "speaker.wave.3.fill", value: String(format: "%.0f dB", recording.peakDecibels), label: String(localized: "Peak dB"))
            }
            .padding(.horizontal)
        }
    }

    private func summaryCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90, height: 100)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Events"))
                .font(.headline)
                .padding(.horizontal)

            if recording.events.isEmpty {
                Text(String(localized: "No events detected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(recording.events) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: SoundEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .foregroundStyle(event.type.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.displayName)
                    .font(.subheadline.bold())
                Text(event.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.0f dB", event.peakDecibels))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Text(String(localized: "SoundScape is not a medical device. Consult a healthcare professional for sleep apnea diagnosis."))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 16)
    }

    // MARK: - Report Text Generation

    private func generateReportText() -> String {
        var text = "SoundScape Sleep Report\n"
        text += "Date: \(recording.formattedDate)\n"
        text += "Time: \(recording.formattedTimeRange)\n"
        text += "Duration: \(recording.formattedDuration)\n"
        text += "Snore Score: \(recording.snoreScore)/100 (\(recording.snoreScoreCategory))\n\n"

        text += "Summary:\n"
        text += "- Snoring: \(String(format: "%.0f", recording.snoringMinutes)) minutes across \(recording.events.filter { $0.type == .snoring }.count) episodes\n"
        text += "- Peak volume: \(String(format: "%.0f", recording.peakDecibels)) dB\n"
        text += "- Total events: \(recording.eventCount)\n\n"

        if !recording.events.isEmpty {
            text += "Events:\n"
            for event in recording.events.sorted(by: { $0.timestamp < $1.timestamp }) {
                text += "\(event.formattedTimestamp) - \(event.type.displayName) (\(event.formattedDuration), \(String(format: "%.0f", event.peakDecibels)) dB)\n"
            }
            text += "\n"
        }

        text += "Note: This report was generated by SoundScape and is not a medical diagnosis.\n"
        return text
    }
}
