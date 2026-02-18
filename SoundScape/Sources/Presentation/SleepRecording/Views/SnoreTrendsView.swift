import SwiftUI
import Charts

struct SnoreTrendsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    var body: some View {
        if sleepRecordingService.recordings.count < 3 {
            emptyState
        } else {
            trendsContent
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Record 3+ nights to see your trends"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < sleepRecordingService.recordings.count ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding()
    }

    // MARK: - Trends Content

    private var trendsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Weekly chart
            weeklyChartSection

            // Stats row
            statsRow

            // Best/Worst nights
            bestWorstSection

            // Streak
            streakSection
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Weekly Chart

    private var weeklyScores: [(date: Date, score: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { dayOffset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            let recording = sleepRecordingService.recordings.first { calendar.isDate($0.date, inSameDayAs: date) }
            return (date, recording?.snoreScore ?? -1)
        }.reversed()
    }

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "This Week"))
                .font(.headline)

            Chart {
                ForEach(weeklyScores, id: \.date) { entry in
                    if entry.score >= 0 {
                        BarMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Score", entry.score)
                        )
                        .foregroundStyle(barColor(for: entry.score))
                        .cornerRadius(4)
                    }
                }
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        }
    }

    private func barColor(for score: Int) -> Color {
        switch score {
        case 0...30: return .green
        case 31...60: return .yellow
        default: return .red
        }
    }

    // MARK: - Stats Row

    private var weeklyAverage: Int {
        let validScores = weeklyScores.filter { $0.score >= 0 }.map(\.score)
        guard !validScores.isEmpty else { return 0 }
        return validScores.reduce(0, +) / validScores.count
    }

    private var previousWeekAverage: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today) else { return 0 }

        let prevWeekRecordings = sleepRecordingService.recordings.filter {
            $0.date >= twoWeeksAgo && $0.date < weekAgo
        }
        guard !prevWeekRecordings.isEmpty else { return 0 }
        return prevWeekRecordings.map(\.snoreScore).reduce(0, +) / prevWeekRecordings.count
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text(String(localized: "Weekly Average"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("\(weeklyAverage)")
                        .font(.title2.bold())
                    trendArrow
                }
            }

            Spacer()

            if thirtyDayRecordingCount >= 7 {
                VStack(spacing: 4) {
                    Text(String(localized: "30-Day Average"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(thirtyDayAverage)")
                        .font(.title2.bold())
                }
            }
        }
    }

    private var trendArrow: some View {
        let delta = weeklyAverage - previousWeekAverage
        let icon: String
        let color: Color

        if delta > 2 {
            icon = "arrow.up"
            color = .red
        } else if delta < -2 {
            icon = "arrow.down"
            color = .green
        } else {
            icon = "arrow.right"
            color = .gray
        }

        return Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(color)
    }

    // MARK: - 30-Day Stats

    private var thirtyDayRecordingCount: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sleepRecordingService.recordings.filter { $0.date >= thirtyDaysAgo }.count
    }

    private var thirtyDayAverage: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = sleepRecordingService.recordings.filter { $0.date >= thirtyDaysAgo }
        guard !recent.isEmpty else { return 0 }
        return recent.map(\.snoreScore).reduce(0, +) / recent.count
    }

    // MARK: - Best/Worst Nights

    private var bestWorstSection: some View {
        let recent = recentRecordings
        guard recent.count >= 2 else { return AnyView(EmptyView()) }

        let best = recent.min(by: { $0.snoreScore < $1.snoreScore })!
        let worst = recent.max(by: { $0.snoreScore < $1.snoreScore })!

        return AnyView(
            HStack(spacing: 16) {
                nightHighlight(
                    label: String(localized: "Best Night"),
                    recording: best,
                    color: .green
                )

                nightHighlight(
                    label: String(localized: "Worst Night"),
                    recording: worst,
                    color: .red
                )
            }
        )
    }

    private func nightHighlight(label: String, recording: SleepRecording, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("\(recording.snoreScore)")
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                Text(recording.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentRecordings: [SleepRecording] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sleepRecordingService.recordings.filter { $0.date >= thirtyDaysAgo }
    }

    // MARK: - Streak

    private var streakSection: some View {
        let streak = calculateStreak()
        return HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text(String(localized: "\(streak) nights recorded"))
                .font(.subheadline)
            Spacer()
        }
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            let hasRecording = sleepRecordingService.recordings.contains {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            if hasRecording {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
        }
        return streak
    }
}
