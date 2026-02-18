import SwiftUI

struct AudioHighlightsView: View {
    let recording: SleepRecording
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var sortByIntensity = true

    private var nonSilentEvents: [SoundEvent] {
        recording.events.filter { $0.type != .silence }
    }

    private var topMoments: [SoundEvent] {
        Array(nonSilentEvents.sorted { $0.peakDecibels > $1.peakDecibels }.prefix(3))
    }

    private var sortedEvents: [SoundEvent] {
        if sortByIntensity {
            return nonSilentEvents.sorted { $0.peakDecibels > $1.peakDecibels }
        } else {
            return nonSilentEvents.sorted { $0.timestamp < $1.timestamp }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Moments
                if !topMoments.isEmpty {
                    Text(String(localized: "Top Moments"))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(topMoments) { event in
                        TopMomentCard(event: event, isPlaying: sleepRecordingService.playingEventId == event.id) {
                            if sleepRecordingService.playingEventId == event.id {
                                sleepRecordingService.stopPlayback()
                            } else {
                                sleepRecordingService.playHighlight(recording: recording, event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Sort toggle
                HStack {
                    Text(String(localized: "All Events"))
                        .font(.headline)
                    Spacer()
                    Picker(String(localized: "Sort"), selection: $sortByIntensity) {
                        Text(String(localized: "Intensity")).tag(true)
                        Text(String(localized: "Time")).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.horizontal)

                // Events list
                ForEach(sortedEvents) { event in
                    EventRow(
                        event: event,
                        isPlaying: sleepRecordingService.playingEventId == event.id
                    ) {
                        if sleepRecordingService.playingEventId == event.id {
                            sleepRecordingService.stopPlayback()
                        } else {
                            sleepRecordingService.playHighlight(recording: recording, event: event)
                        }
                    }
                    .padding(.horizontal)
                }

                // Medical disclaimer
                Text(String(localized: "SoundScape is not a medical device. Consult a healthcare professional for sleep apnea diagnosis."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.top)
        }
        .navigationTitle(String(localized: "Audio Highlights"))
        .onDisappear {
            sleepRecordingService.stopPlayback()
        }
    }
}

// MARK: - Top Moment Card

struct TopMomentCard: View {
    let event: SoundEvent
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(event.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: event.type.icon)
                        .foregroundStyle(event.type.color)
                    Text(event.type.displayName)
                        .font(.subheadline.bold())
                }
                HStack(spacing: 8) {
                    Text(event.formattedTimestamp)
                    Text("\u{00B7}")
                    Text(event.formattedDuration)
                    Text("\u{00B7}")
                    Text("\(Int(event.peakDecibels)) dB")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: SoundEvent
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(event.type.color)
            }

            Image(systemName: event.type.icon)
                .foregroundStyle(event.type.color)
                .frame(width: 20)

            Text(event.type.displayName)
                .font(.subheadline)

            Spacer()

            Text(event.formattedTimestamp)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(event.formattedDuration)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Intensity bar
            GeometryReader { geometry in
                let width = geometry.size.width * CGFloat(min(1, event.peakDecibels / 90))
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.type.color)
                    .frame(width: max(4, width), height: 8)
            }
            .frame(width: 40, height: 8)
        }
        .padding(.vertical, 4)
    }
}
