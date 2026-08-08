import SwiftUI

/// Editorial Weekly Stats card — the in-scope slice of the Insights tab.
///
/// Mirrors `screenshots/design-refs/ref02-warm-dashboard.jpg`: a cream
/// container with a chevron header row, a large yellow primary stat tile
/// with a hand-drawn sparkline, a peach + orange two-tile stat row, and an
/// orange bar-chart tile beneath. Pure presentation — the caller supplies a
/// `Stats` value type.
struct WeeklyStatsCardView: View {

    // MARK: - Stats value type

    /// Snapshot of the metrics rendered by the card. Pass real values from
    /// `InsightsService` when available, or a hard-coded sample otherwise.
    struct Stats: Equatable {
        var activeMinutes: Int
        var totalSessions: Int
        var streakDays: Int
        /// Last three nightly averages in hours; rendered as the three bars
        /// in the bar-chart tile.
        var nightlyHours: [Double]
        /// Normalised (0…1) values for the sparkline. Last value is the
        /// rightmost point. Should contain ≥ 2 entries.
        var sparkline: [Double]

        static let sample = Stats(
            activeMinutes: 234,
            totalSessions: 12,
            streakDays: 5,
            nightlyHours: [3.6, 4.0, 4.1],
            sparkline: [0.2, 0.3, 0.35, 0.42, 0.5, 0.72, 0.95]
        )
    }

    let stats: Stats
    let monthYearLabel: String

    init(stats: Stats, monthYearLabel: String = WeeklyStatsCardView.defaultMonthYearLabel()) {
        self.stats = stats
        self.monthYearLabel = monthYearLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chevronHeader

            activeMinutesTile

            HStack(spacing: 12) {
                totalSessionsTile
                streakTile
            }

            nightlyAvgBarChartTile
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusBlock, style: .continuous)
                .fill(Tokens.colorCream)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Weekly information"))
    }

    // MARK: - Header

    private var chevronHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right.2")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Tokens.colorInk)
                    .accessibilityHidden(true)

                Text("Weekly Information")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Tokens.colorInk)

                Spacer(minLength: 0)

                Text(monthYearLabel)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Tokens.colorInk.opacity(0.45))
                    .accessibilityLabel(Text("Period \(monthYearLabel)"))
            }

            Rectangle()
                .fill(Tokens.colorInk.opacity(0.18))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Primary stat tile (yellow + sparkline)

    private var activeMinutesTile: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .fill(Tokens.colorYellow)

            VStack(alignment: .leading, spacing: 0) {
                Text("Active Minutes")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Tokens.colorInk)

                Text("\(stats.activeMinutes)")
                    .font(.system(size: Tokens.displayNumeralSize, weight: .black, design: .default))
                    .foregroundStyle(Tokens.colorInk)
                    .kerning(-2)
                    .padding(.top, 4)
                    .accessibilityLabel(Text("\(stats.activeMinutes) active minutes this week"))

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    Text("7 days ago")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Tokens.colorInk.opacity(0.55))

                    Spacer()

                    Text("Today")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Tokens.colorInk.opacity(0.55))
                }
            }
            .padding(16)

            // Sparkline overlays the right half of the tile, anchored bottom.
            GeometryReader { geo in
                sparklinePath(in: geo.size)
                    .stroke(
                        Tokens.colorInk,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 36)
            .allowsHitTesting(false)
        }
        .frame(height: 200)
    }

    private func sparklinePath(in size: CGSize) -> Path {
        let values = stats.sparkline
        guard values.count >= 2 else { return Path() }

        // Sparkline occupies the right ~55% of the tile width, hugging the
        // bottom — echoes the hand-drawn underline in ref02.
        let startX = size.width * 0.45
        let width = size.width - startX
        let heightBand = size.height * 0.55
        let baseY = size.height

        let maxValue = max(values.max() ?? 1, 0.0001)
        let stepX = width / CGFloat(values.count - 1)

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = startX + CGFloat(index) * stepX
            let normalized = CGFloat(value / maxValue)
            let y = baseY - normalized * heightBand
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    // MARK: - Secondary stat row

    private var totalSessionsTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total sessions")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Tokens.colorInk)

            Text("\(stats.totalSessions)")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(Tokens.colorInk)
                .kerning(-1)

            Text("+2 from last week")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Tokens.colorInk.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .fill(Tokens.colorPeach)
        )
        .accessibilityElement(children: .combine)
    }

    private var streakTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Streak")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Tokens.colorCream)

            Text("\(stats.streakDays)d")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(Tokens.colorCream)
                .kerning(-1)

            Text("+1 from last week")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Tokens.colorCream.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .fill(Tokens.colorOrange)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Bar chart tile

    private var nightlyAvgBarChartTile: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nightly avg (hr)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Tokens.colorCream)

            HStack(alignment: .bottom, spacing: 16) {
                ForEach(Array(stats.nightlyHours.enumerated()), id: \.offset) { _, hours in
                    barColumn(hours: hours)
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .fill(Tokens.colorOrange)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Nightly average hours"))
    }

    private func barColumn(hours: Double) -> some View {
        let maxBarHours = max(stats.nightlyHours.max() ?? 1, 0.0001)
        let normalized = CGFloat(hours / maxBarHours)

        return VStack(spacing: 6) {
            Text(String(format: "%.1f", hours))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Tokens.colorCream)
                .accessibilityHidden(true)

            GeometryReader { geo in
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Tokens.colorInk.opacity(0.85))
                        .frame(height: max(geo.size.height * normalized, 4))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(String(format: "%.1f", hours)) hours"))
    }

    // MARK: - Helpers

    static func defaultMonthYearLabel(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    ScrollView {
        WeeklyStatsCardView(stats: .sample)
            .padding(24)
    }
    .background(Tokens.colorCream.ignoresSafeArea())
}
