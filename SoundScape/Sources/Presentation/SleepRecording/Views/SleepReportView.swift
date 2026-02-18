import SwiftUI

struct SleepReportView: View {
    let recording: SleepRecording
    @Environment(\.dismiss) private var dismiss
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text(recording.formattedDate + " \u{00B7} " + recording.formattedTimeRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Snore Score gauge
                    snoreScoreView

                    // Summary cards
                    summaryCardsView

                    // Timeline chart
                    SleepTimelineChart(recording: recording)
                        .frame(height: 200)
                        .padding(.horizontal)

                    // Events list
                    eventsListView

                    // Listen to highlights
                    if !recording.events.filter({ $0.type != .silence }).isEmpty {
                        NavigationLink {
                            AudioHighlightsView(recording: recording)
                        } label: {
                            Label(String(localized: "Listen to Highlights"), systemImage: "play.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    // Medical disclaimer
                    Text(String(localized: "SoundScape is not a medical device. Consult a healthcare professional for sleep apnea diagnosis."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationTitle(String(localized: "Sleep Report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Done")) {
                        sleepRecordingService.dismissReport()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: sleepRecordingService.generateReportText(for: recording)) {
                        Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Snore Score

    private var snoreScoreView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(recording.snoreScoreCategoryColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: CGFloat(recording.snoreScore) / 100)
                    .stroke(recording.snoreScoreCategoryColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(recording.snoreScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(recording.snoreScoreCategory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(String(localized: "Snore Score"))
                .font(.headline)
        }
        .padding()
    }

    // MARK: - Summary Cards

    private var summaryCardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(icon: "clock.fill", value: recording.formattedDuration, label: String(localized: "Duration"))
                SummaryCard(icon: "zzz", value: "\(recording.snoringMinutes) min", label: String(localized: "Snoring"))
                SummaryCard(icon: "waveform", value: "\(recording.eventCount)", label: String(localized: "Events"))
                SummaryCard(icon: "speaker.wave.3.fill", value: "\(Int(recording.peakDecibels)) dB", label: String(localized: "Peak dB"))
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Events List

    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Events"))
                .font(.headline)
                .padding(.horizontal)

            if recording.events.filter({ $0.type != .silence }).isEmpty {
                Text(String(localized: "No events detected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(recording.events.filter { $0.type != .silence }.sorted { $0.timestamp < $1.timestamp }) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.type.icon)
                            .foregroundStyle(event.type.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.displayName)
                                .font(.subheadline)
                            Text(event.formattedTimestamp)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(event.peakDecibels)) dB")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(event.type.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80, height: 90)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
