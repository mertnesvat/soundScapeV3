import SwiftUI

struct InsightsView: View {
    @Environment(InsightsService.self) private var insightsService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService

    private var isPremiumRequired: Bool {
        premiumManager.isPremiumRequired(for: .fullInsights)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.padding.edges) {
                        // Sleep Recording entry row
                        sleepRecordingRow

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
                            WeeklySleepChartView(data: insightsService.weeklyData)

                            MetricsGridView(
                                averageDuration: insightsService.averageDuration,
                                averageQuality: insightsService.averageQuality,
                                averageTimeToSleep: insightsService.averageTimeToSleep
                            )

                            if insightsService.sleepGoal != nil {
                                SleepGoalView(
                                    progress: insightsService.goalProgress,
                                    targetHours: (insightsService.sleepGoal?.targetDuration ?? 0) / 3600,
                                    actualHours: insightsService.averageDuration / 3600
                                )
                            }

                            TopSoundsView(sounds: insightsService.mostUsedSounds)

                            RecommendationsView(recommendations: insightsService.recommendations)
                        }

                        UsageStatisticsView(
                            totalSessions: insightsService.totalSessions,
                            totalSleepTime: insightsService.totalSleepTime
                        )
                    }
                    .padding(DesignTokens.padding.standard)
                }
            }
            .navigationTitle(LocalizedStringKey("Insights"))
            .onAppear {
                analyticsService.logInsightsTabOpened(hasData: insightsService.totalSessions > 0)
            }
            .sheet(isPresented: Binding(
                get: { paywallService.showPaywall },
                set: { newValue in
                    if !newValue {
                        paywallService.handlePaywallDismissed()
                    }
                }
            )) {
                OnboardingPaywallView(
                    onComplete: {
                        paywallService.showPaywall = false
                    },
                    isPresented: true
                )
                .environment(onboardingService)
                .environment(paywallService)
                .environment(subscriptionService)
            }
        }
    }

    // MARK: - Sleep Recording Row

    private var sleepRecordingRow: some View {
        NavigationLink {
            SleepRecordingView()
        } label: {
            HStack(spacing: DesignTokens.padding.standard) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("Sleep recording"))
                        .font(.body.weight(DesignTokens.font.body))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(LocalizedStringKey("Track snoring and sleep sounds overnight"))
                        .font(.caption.weight(DesignTokens.font.body))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DesignTokens.accent)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, DesignTokens.padding.compact)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Sleep recording"))
    }

    // MARK: - Basic Stats (Free Tier)

    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.padding.standard) {
            Text(LocalizedStringKey("Your Sleep Journey"))
                .font(.headline.weight(DesignTokens.font.header))
                .foregroundStyle(.primary)

            HStack(spacing: DesignTokens.padding.standard) {
                basicStatCard(
                    title: String(localized: "Total Sessions"),
                    value: "\(insightsService.totalSessions)",
                    icon: "moon.zzz.fill"
                )

                basicStatCard(
                    title: String(localized: "This Week"),
                    value: "\(insightsService.weeklyData.count)",
                    icon: "calendar"
                )
            }
        }
    }

    private func basicStatCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(DesignTokens.accent)
                Text(title)
                    .font(.caption.weight(DesignTokens.font.body))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title.weight(DesignTokens.font.header))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.padding.standard)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radius.button)
                .fill(DesignTokens.accent.opacity(0.08))
        )
    }

    // MARK: - Premium Upsell Card

    private var premiumUpsellCard: some View {
        Button {
            paywallService.triggerPaywall(placement: "full_insights") {}
        } label: {
            HStack(spacing: DesignTokens.padding.standard) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(DesignTokens.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("Unlock Full Analytics"))
                        .font(.headline.weight(DesignTokens.font.header))
                        .foregroundStyle(.primary)

                    Text(LocalizedStringKey("Charts, trends, recommendations & more"))
                        .font(.caption.weight(DesignTokens.font.body))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DesignTokens.accent)
            }
            .padding(DesignTokens.padding.standard)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radius.card)
                    .fill(DesignTokens.accent.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Locked Sections

    private var lockedWeeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "Weekly Sleep Trends"), icon: "chart.bar.fill")
            lockedPlaceholder(height: 180)
        }
    }

    private var lockedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "Sleep Metrics"), icon: "heart.fill")
            lockedPlaceholder(height: 100)
        }
    }

    private var lockedTopSoundsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "Top Sounds"), icon: "waveform")
            lockedPlaceholder(height: 120)
        }
    }

    private var lockedRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "Personalized Tips"), icon: "lightbulb.fill")
            lockedPlaceholder(height: 100)
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DesignTokens.accent)
            Text(title)
                .font(.headline.weight(DesignTokens.font.header))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func lockedPlaceholder(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DesignTokens.radius.button)
            .fill(DesignTokens.accent.opacity(0.06))
            .frame(height: height)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(LocalizedStringKey("Premium Feature"))
                        .font(.caption.weight(DesignTokens.font.body))
                        .foregroundStyle(.secondary)
                }
            )
            .onTapGesture {
                paywallService.triggerPaywall(placement: "full_insights") {}
            }
    }
}

#Preview("Premium User") {
    let paywallService = PaywallService()
    InsightsView()
        .environment(InsightsService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}

#Preview("Free User") {
    let paywallService = PaywallService()
    InsightsView()
        .environment(InsightsService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
