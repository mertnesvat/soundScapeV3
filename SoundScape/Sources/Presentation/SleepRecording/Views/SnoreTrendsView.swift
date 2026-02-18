import SwiftUI

struct SnoreTrendsView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService

    private var recentRecordings: [SleepRecording] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sleepRecordingService.recordings.filter { $0.date >= sevenDaysAgo }
    }

    private var thirtyDayRecordings: [SleepRecording] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sleepRecordingService.recordings.filter { $0.date >= thirtyDaysAgo }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if sleepRecordingService.recordings.count < 3 {
                    emptyTrendsView
                } else {
                    weeklyChartSection
                    weeklyAverageSection
                    bestWorstSection

                    if thirtyDayRecordings.count >= 7 {
                        thirtyDaySection
                    }

                    streakSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey("Trends"))
    }

    // MARK: - Empty State

    private var emptyTrendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(String(localized: "Record 3+ nights to see your trends"))
                .font(.headline)
                .foregroundStyle(.secondary)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < sleepRecordingService.recordings.count ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "This Week"))
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData(), id: \.dayLabel) { day in
                    VStack(spacing: 4) {
                        if let score = day.score {
                            Text("\(score)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.score != nil ? barColor(for: day.score!) : Color.gray.opacity(0.15))
                            .frame(height: day.score != nil ? max(8, CGFloat(day.score!) * 1.4) : 8)
                            .frame(maxWidth: .infinity)

                        Text(day.dayLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Average

    private var weeklyAverageSection: some View {
        let currentAvg = weeklyAverage(for: recentRecordings)
        let previousWeekStart = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let previousWeekEnd = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let previousRecordings = sleepRecordingService.recordings.filter {
            $0.date >= previousWeekStart && $0.date < previousWeekEnd
        }
        let previousAvg = weeklyAverage(for: previousRecordings)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Weekly Average"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("\(currentAvg)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(scoreColor(currentAvg))

                    if previousAvg > 0 {
                        let delta = currentAvg - previousAvg
                        HStack(spacing: 2) {
                            Image(systemName: delta > 0 ? "arrow.up" : delta < 0 ? "arrow.down" : "minus")
                                .font(.caption)
                            Text("\(abs(delta))")
                                .font(.caption)
                        }
                        .foregroundStyle(delta > 0 ? .red : delta < 0 ? .green : .secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Best / Worst

    private var bestWorstSection: some View {
        let sorted = recentRecordings.sorted { $0.snoreScore < $1.snoreScore }

        return HStack(spacing: 12) {
            if let best = sorted.first {
                statCard(
                    title: String(localized: "Best Night"),
                    score: best.snoreScore,
                    date: best.formattedDate,
                    color: .green
                )
            }

            if let worst = sorted.last, sorted.count > 1 {
                statCard(
                    title: String(localized: "Worst Night"),
                    score: worst.snoreScore,
                    date: worst.formattedDate,
                    color: .red
                )
            }
        }
    }

    private func statCard(title: String, score: Int, date: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(score)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)

            Text(date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 30 Day Average

    private var thirtyDaySection: some View {
        let avg = weeklyAverage(for: thirtyDayRecordings)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "30-Day Average"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(avg)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(scoreColor(avg))
            }

            Spacer()

            Text("\(thirtyDayRecordings.count)")
                .font(.title2)
                .fontWeight(.bold)
            + Text(String(localized: " nights"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak

    private var streakSection: some View {
        let streak = calculateStreak()

        return HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)")
                    .font(.title2)
                    .fontWeight(.bold)
                + Text(String(localized: " nights recorded"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(String(localized: "Keep recording to build your streak!"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private struct DayData {
        let dayLabel: String
        let score: Int?
    }

    private func weeklyData() -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayLabel = dayFormatter.string(from: date)

            let recording = recentRecordings.first { recording in
                calendar.isDate(recording.date, inSameDayAs: date)
            }

            return DayData(dayLabel: dayLabel, score: recording?.snoreScore)
        }
    }

    private func weeklyAverage(for recordings: [SleepRecording]) -> Int {
        guard !recordings.isEmpty else { return 0 }
        let total = recordings.reduce(0) { $0 + $1.snoreScore }
        return total / recordings.count
    }

    private func barColor(for score: Int) -> Color {
        if score <= 30 { return .green }
        if score <= 60 { return .yellow }
        return .red
    }

    private func scoreColor(_ score: Int) -> Color {
        if score <= 30 { return .green }
        if score <= 60 { return .yellow }
        return .red
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let hasRecording = sleepRecordingService.recordings.contains { recording in
                calendar.isDate(recording.date, inSameDayAs: checkDate)
            }

            if hasRecording {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }
}

#Preview {
    NavigationStack {
        SnoreTrendsView()
            .environment(SleepRecordingService())
    }
    .preferredColorScheme(.dark)
}
