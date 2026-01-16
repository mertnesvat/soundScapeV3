import SwiftUI

struct InsightsView: View {
    @Environment(InsightsService.self) private var insightsService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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

                    // Usage Statistics
                    UsageStatisticsView(
                        totalSessions: insightsService.totalSessions,
                        totalSleepTime: insightsService.totalSleepTime
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
        .environment(InsightsService())
        .preferredColorScheme(.dark)
}
