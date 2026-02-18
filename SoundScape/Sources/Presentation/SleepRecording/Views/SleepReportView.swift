import SwiftUI

struct SleepReportView: View {
    let recording: SleepRecording
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Snore Score
                snoreScoreSection

                // Summary cards
                summaryCardsSection

                // Timeline chart
                SleepTimelineChart(recording: recording)
                    .frame(height: 200)
                    .padding(.horizontal)

                // Events list
                eventsListSection

                // Medical disclaimer
                disclaimerSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey("Sleep Report"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "Done")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: generateReportText()) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(recording.formattedDate)
                .font(.headline)
            Text(recording.formattedTimeRange)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Snore Score

    private var snoreScoreSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(recording.snoreScoreCategory.color.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: CGFloat(recording.snoreScore) / 100.0)
                    .stroke(recording.snoreScoreCategory.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(recording.snoreScore)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(recording.snoreScoreCategory.color)

                    Text(recording.snoreScoreCategory.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                summaryCard(
                    icon: "clock.fill",
                    value: recording.formattedDuration,
                    label: String(localized: "Duration"),
                    color: .blue
                )
                summaryCard(
                    icon: "zzz",
                    value: String(format: "%.0f min", recording.snoringMinutes),
                    label: String(localized: "Snoring"),
                    color: .orange
                )
                summaryCard(
                    icon: "waveform",
                    value: "\(recording.eventCount)",
                    label: String(localized: "Events"),
                    color: .purple
                )
                summaryCard(
                    icon: "speaker.wave.3.fill",
                    value: "\(Int(recording.peakDecibels)) dB",
                    label: String(localized: "Peak dB"),
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }

    private func summaryCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90, height: 100)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Events List

    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Events"))
                .font(.headline)
                .padding(.horizontal)

            if recording.events.filter({ $0.type != .silence }).isEmpty {
                Text(String(localized: "No significant events detected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(recording.events.filter { $0.type != .silence }) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.type.icon)
                            .font(.title3)
                            .foregroundStyle(event.type.color)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.displayName)
                                .font(.subheadline)
                            Text(event.formattedTimestamp)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(event.formattedDuration)
                                .font(.subheadline)
                            Text("\(Int(event.peakDecibels)) dB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Text(String(localized: "SoundScape is not a medical device. Consult a healthcare professional for sleep apnea diagnosis."))
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 8)
    }

    // MARK: - Report Generation

    private func generateReportText() -> String {
        var report = "SoundScape Sleep Report\n"
        report += "Date: \(recording.formattedDate)\n"
        report += "Time: \(recording.formattedTimeRange)\n"
        report += "Duration: \(recording.formattedDuration)\n"
        report += "Snore Score: \(recording.snoreScore)/100 (\(recording.snoreScoreCategory.displayName))\n\n"

        report += "Summary:\n"
        report += "- Snoring: \(String(format: "%.0f", recording.snoringMinutes)) minutes across \(recording.events.filter { $0.type == .snoring }.count) episodes\n"
        report += "- Peak volume: \(Int(recording.peakDecibels)) dB\n"
        report += "- Events: \(recording.eventCount)\n\n"

        if !recording.events.filter({ $0.type != .silence }).isEmpty {
            report += "Events:\n"
            for event in recording.events.filter({ $0.type != .silence }) {
                report += "\(event.formattedTimestamp) - \(event.type.displayName) (\(event.formattedDuration), \(Int(event.peakDecibels)) dB)\n"
            }
            report += "\n"
        }

        report += "Note: This report was generated by SoundScape and is not a medical diagnosis."

        return report
    }
}

#Preview {
    NavigationStack {
        SleepReportView(recording: SleepRecording(
            date: Date().addingTimeInterval(-28800),
            endDate: Date(),
            duration: 27120,
            events: [
                SoundEvent(timestamp: 3600, duration: 15, type: .snoring, peakDecibels: 60, averageDecibels: 52),
                SoundEvent(timestamp: 7200, duration: 3, type: .loudSound, peakDecibels: 72, averageDecibels: 68),
                SoundEvent(timestamp: 14400, duration: 8, type: .talking, peakDecibels: 55, averageDecibels: 48)
            ],
            decibelSamples: (0..<100).map { _ in Float.random(in: 25...65) },
            averageDecibels: 35,
            peakDecibels: 72,
            snoreScore: 45
        ))
    }
    .preferredColorScheme(.dark)
}
