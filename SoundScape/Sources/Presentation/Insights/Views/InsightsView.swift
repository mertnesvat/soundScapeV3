import SwiftUI

struct InsightsView: View {
    @Environment(InsightsService.self) private var insightsService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager

    private var isPremiumRequired: Bool {
        premiumManager.isPremiumRequired(for: .fullInsights)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Free tier: Basic stats always visible
                    basicStatsSection

                    if isPremiumRequired {
                        // Free tier: Show premium upsell card
                        premiumUpsellCard

                        // Show locked versions of premium content
                        lockedWeeklyChartSection
                        lockedMetricsSection
                        lockedTopSoundsSection
                        lockedRecommendationsSection
                    } else {
                        // Premium tier: Full dashboard
                        // Weekly Sleep Chart
                        WeeklySleepChartView(data: insightsService.weeklyData)

                        // Key Metrics
                        MetricsGridView(
                            averageDuration: insightsService.averageDuration,
                            averageQuality: insightsService.averageQuality,
                            averageTimeToSleep: insightsService.averageTimeToSleep
                        )

                        // Sleep Goal Progress
                        if insightsService.sleepGoal != nil {
                            SleepGoalView(
                                progress: insightsService.goalProgress,
                                targetHours: (insightsService.sleepGoal?.targetDuration ?? 0) / 3600,
                                actualHours: insightsService.averageDuration / 3600
                            )
                        }

                        // Top Sounds
                        TopSoundsView(sounds: insightsService.mostUsedSounds)

                        // Recommendations
                        RecommendationsView(recommendations: insightsService.recommendations)
                    }

                    // Usage Statistics - always visible
                    UsageStatisticsView(
                        totalSessions: insightsService.totalSessions,
                        totalSleepTime: insightsService.totalSleepTime
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Insights"))
        }
    }

    // MARK: - Basic Stats (Free Tier)

    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Sleep Journey")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                basicStatCard(
                    title: "Total Sessions",
                    value: "\(insightsService.totalSessions)",
                    icon: "moon.zzz.fill",
                    color: .indigo
                )

                basicStatCard(
                    title: "This Week",
                    value: "\(insightsService.weeklyData.count)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
    }

    private func basicStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Premium Upsell Card

    private var premiumUpsellCard: some View {
        Button {
            paywallService.triggerPaywall(placement: "campaign_trigger") {}
        } label: {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlock Full Analytics")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Charts, trends, recommendations & more")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Locked Sections

    private var lockedWeeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Weekly Sleep Trends", icon: "chart.bar.fill")
            lockedPlaceholder(height: 180)
        }
    }

    private var lockedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Sleep Metrics", icon: "heart.fill")
            lockedPlaceholder(height: 100)
        }
    }

    private var lockedTopSoundsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Top Sounds", icon: "waveform")
            lockedPlaceholder(height: 120)
        }
    }

    private var lockedRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Personalized Tips", icon: "lightbulb.fill")
            lockedPlaceholder(height: 100)
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func lockedPlaceholder(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: height)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Premium Feature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .onTapGesture {
                paywallService.triggerPaywall(placement: "campaign_trigger") {}
            }
    }
}

#Preview("Premium User") {
    let paywallService = PaywallService()
    InsightsView()
        .environment(InsightsService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}

#Preview("Free User") {
    let paywallService = PaywallService()
    InsightsView()
        .environment(InsightsService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
