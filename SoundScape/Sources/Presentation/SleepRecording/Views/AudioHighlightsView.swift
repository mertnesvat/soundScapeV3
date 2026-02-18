import SwiftUI

struct AudioHighlightsView: View {
    let recording: SleepRecording

    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var sortByIntensity = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Moments
                if topMoments.count > 0 {
                    topMomentsSection
                }

                // Sort toggle
                sortToggle

                // Full events list
                eventsListSection

                // Medical disclaimer
                Text(String(localized: "SoundScape is not a medical device. Consult a healthcare professional for sleep apnea diagnosis."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
            }
            .padding(.vertical)
        }
        .navigationTitle(String(localized: "Audio Highlights"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            sleepRecordingService.stopPlayback()
        }
    }

    // MARK: - Top Moments

    private var topMoments: [SoundEvent] {
        Array(
            recording.events
                .filter { $0.type != .silence }
                .sorted { $0.peakDecibels > $1.peakDecibels }
                .prefix(3)
        )
    }

    private var topMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Top Moments"))
                .font(.headline)
                .padding(.horizontal)

            ForEach(topMoments) { event in
                topMomentCard(event)
            }
        }
    }

    private func topMomentCard(_ event: SoundEvent) -> some View {
        let isPlaying = sleepRecordingService.playingEventId == event.id

        return HStack(spacing: 16) {
            Button {
                if isPlaying {
                    sleepRecordingService.stopPlayback()
                } else {
                    sleepRecordingService.playHighlight(recording: recording, event: event)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(event.type.color)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: event.type.icon)
                        .foregroundStyle(event.type.color)
                    Text(event.type.displayName)
                        .font(.subheadline.bold())
                }
                Text(event.formattedTimestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f dB", event.peakDecibels))
                    .font(.headline)
                Text(event.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Sort Toggle

    private var sortToggle: some View {
        Picker(String(localized: "Sort"), selection: $sortByIntensity) {
            Text(String(localized: "By Intensity")).tag(true)
            Text(String(localized: "Chronological")).tag(false)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Events List

    private var sortedEvents: [SoundEvent] {
        let nonSilence = recording.events.filter { $0.type != .silence }
        if sortByIntensity {
            return nonSilence.sorted { $0.peakDecibels > $1.peakDecibels }
        }
        return nonSilence.sorted { $0.timestamp < $1.timestamp }
    }

    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "All Events"))
                .font(.headline)
                .padding(.horizontal)

            ForEach(sortedEvents) { event in
                eventRow(event)
            }
        }
    }

    private func eventRow(_ event: SoundEvent) -> some View {
        let isPlaying = sleepRecordingService.playingEventId == event.id

        return HStack(spacing: 12) {
            Button {
                if isPlaying {
                    sleepRecordingService.stopPlayback()
                } else {
                    sleepRecordingService.playHighlight(recording: recording, event: event)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(event.type.color, in: Circle())
            }
            .buttonStyle(.plain)

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

            VStack(alignment: .trailing, spacing: 2) {
                Text(event.formattedDuration)
                    .font(.caption)
                // Intensity bar
                GeometryReader { geo in
                    let maxDB: Float = recording.peakDecibels > 0 ? recording.peakDecibels : 100
                    let width = CGFloat(event.peakDecibels / maxDB) * geo.size.width
                    RoundedRectangle(cornerRadius: 2)
                        .fill(event.type.color.opacity(0.6))
                        .frame(width: max(4, width), height: 4)
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
