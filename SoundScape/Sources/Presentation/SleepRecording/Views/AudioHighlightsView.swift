import SwiftUI
import AVFoundation

struct AudioHighlightsView: View {
    let recording: SleepRecording
    @Environment(\.dismiss) private var dismiss
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playingEventId: UUID?
    @State private var sortByIntensity = true
    @State private var playbackProgress: Double = 0
    @State private var progressTimer: Timer?

    private var nonSilenceEvents: [SoundEvent] {
        recording.events.filter { $0.type != .silence }
    }

    private var sortedEvents: [SoundEvent] {
        if sortByIntensity {
            return nonSilenceEvents.sorted { $0.peakDecibels > $1.peakDecibels }
        } else {
            return nonSilenceEvents.sorted { $0.timestamp < $1.timestamp }
        }
    }

    private var topMoments: [SoundEvent] {
        Array(nonSilenceEvents.sorted { $0.peakDecibels > $1.peakDecibels }.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Top moments
                if !topMoments.isEmpty {
                    topMomentsSection
                }

                // Sort control
                sortControlSection

                // Full events list
                eventsListSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey("Audio Highlights"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Done")) {
                    stopPlayback()
                    dismiss()
                }
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }

    // MARK: - Top Moments

    private var topMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Top Moments"))
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topMoments) { event in
                        topMomentCard(event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func topMomentCard(_ event: SoundEvent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: event.type.icon)
                    .foregroundStyle(event.type.color)
                Spacer()
                Text("\(Int(event.peakDecibels)) dB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(event.type.displayName)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(event.formattedTimestamp)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(event.formattedDuration)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                togglePlayback(for: event)
            } label: {
                Image(systemName: playingEventId == event.id ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(event.type.color)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sort Control

    private var sortControlSection: some View {
        Picker(String(localized: "Sort"), selection: $sortByIntensity) {
            Text(String(localized: "Loudest")).tag(true)
            Text(String(localized: "Chronological")).tag(false)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Events List

    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedEvents) { event in
                eventRow(event)
            }
        }
        .padding(.horizontal)
    }

    private func eventRow(_ event: SoundEvent) -> some View {
        HStack(spacing: 12) {
            Button {
                togglePlayback(for: event)
            } label: {
                Image(systemName: playingEventId == event.id ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(event.type.color)
            }

            Image(systemName: event.type.icon)
                .font(.title3)
                .foregroundStyle(event.type.color)
                .frame(width: 28)

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

                // Intensity bar
                GeometryReader { geo in
                    let maxDB = recording.peakDecibels > 0 ? recording.peakDecibels : 1
                    let ratio = CGFloat(event.peakDecibels / maxDB)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(event.type.color.opacity(0.3))
                        .frame(width: geo.size.width)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(event.type.color)
                                .frame(width: geo.size.width * ratio)
                        }
                }
                .frame(width: 50, height: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            playingEventId == event.id
                ? event.type.color.opacity(0.1)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Playback

    private func togglePlayback(for event: SoundEvent) {
        if playingEventId == event.id {
            stopPlayback()
        } else {
            playHighlight(event: event)
        }
    }

    private func playHighlight(event: SoundEvent) {
        stopPlayback()

        guard FileManager.default.fileExists(atPath: recording.fileURL.path) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: recording.fileURL)
            player.prepareToPlay()

            // Seek to event timestamp with 1.5 second buffer before
            let startTime = max(0, event.timestamp - 1.5)
            player.currentTime = startTime
            player.play()

            audioPlayer = player
            playingEventId = event.id
            isPlaying = true

            // Stop after event duration + 3 seconds buffer
            let playDuration = event.duration + 3.0
            progressTimer = Timer.scheduledTimer(withTimeInterval: playDuration, repeats: false) { [self] _ in
                Task { @MainActor in
                    self.stopPlayback()
                }
            }
        } catch {
            print("Error playing highlight: \(error)")
        }
    }

    private func stopPlayback() {
        progressTimer?.invalidate()
        progressTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingEventId = nil
        isPlaying = false
        playbackProgress = 0
    }
}

#Preview {
    NavigationStack {
        AudioHighlightsView(recording: SleepRecording(
            date: Date().addingTimeInterval(-28800),
            endDate: Date(),
            duration: 27120,
            events: [
                SoundEvent(timestamp: 3600, duration: 15, type: .snoring, peakDecibels: 60, averageDecibels: 52),
                SoundEvent(timestamp: 7200, duration: 3, type: .loudSound, peakDecibels: 72, averageDecibels: 68),
                SoundEvent(timestamp: 10800, duration: 20, type: .snoring, peakDecibels: 58, averageDecibels: 50),
                SoundEvent(timestamp: 14400, duration: 8, type: .talking, peakDecibels: 55, averageDecibels: 48)
            ],
            averageDecibels: 35,
            peakDecibels: 72,
            snoreScore: 45
        ))
    }
    .preferredColorScheme(.dark)
}
