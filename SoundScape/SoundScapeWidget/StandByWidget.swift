import SwiftUI
import WidgetKit

/// StandBy Widget for iOS 17+ nightstand mode
/// Displays time, playing sounds, and timer countdown
struct StandByWidget: Widget {
    let kind: String = "StandByWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StandByTimelineProvider()) { entry in
            StandByWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SoundScape")
        .description("View playing sounds and sleep timer in StandBy mode.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Timeline Entry

struct StandByEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let soundNames: String
    let timerRemaining: String?
}

// MARK: - Timeline Provider

struct StandByTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StandByEntry {
        StandByEntry(
            date: Date(),
            isPlaying: true,
            soundNames: "Rain & Thunder",
            timerRemaining: "45:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StandByEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StandByEntry>) -> Void) {
        let currentDate = Date()
        var entries: [StandByEntry] = []

        // Generate entries for the next 60 minutes (refresh every minute)
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) ?? currentDate
            let entry = createEntry(for: entryDate)
            entries.append(entry)
        }

        // Refresh timeline after an hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry(for date: Date) -> StandByEntry {
        if let state = WidgetSharedState.load() {
            return StandByEntry(
                date: date,
                isPlaying: state.isPlaying,
                soundNames: state.displaySoundNames,
                timerRemaining: state.timerRemainingFormatted
            )
        }

        // Default state when no data available
        return StandByEntry(
            date: date,
            isPlaying: false,
            soundNames: "Tap to open SoundScape",
            timerRemaining: nil
        )
    }
}

// MARK: - Widget View

struct StandByWidgetView: View {
    var entry: StandByEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Time display
            Text(entry.date, style: .time)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(entry.isPlaying ? .primary : .secondary)

            // Sound names with playing indicator
            HStack(spacing: 4) {
                if entry.isPlaying {
                    // Animated sound wave indicator
                    SoundWaveIndicator()
                }

                Text(entry.soundNames)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(entry.isPlaying ? .primary : .tertiary)
                    .lineLimit(1)
            }

            // Timer countdown if active
            if let timer = entry.timerRemaining {
                HStack(spacing: 2) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 8))
                    Text(timer)
                        .font(.system(.caption2, design: .monospaced))
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sound Wave Indicator

struct SoundWaveIndicator: View {
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.primary)
                    .frame(width: 2, height: barHeight(for: index))
            }
        }
        .frame(width: 10, height: 10)
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Static heights for widget (no animation)
        switch index {
        case 0: return 4
        case 1: return 8
        case 2: return 6
        default: return 4
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    StandByWidget()
} timeline: {
    StandByEntry(date: .now, isPlaying: true, soundNames: "Rain & Thunder", timerRemaining: "45:00")
    StandByEntry(date: .now, isPlaying: true, soundNames: "Brown Noise", timerRemaining: nil)
    StandByEntry(date: .now, isPlaying: false, soundNames: "Tap to open SoundScape", timerRemaining: nil)
}
