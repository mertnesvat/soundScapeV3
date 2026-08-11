import SwiftUI

/// Combined Sleep tab containing Wind Down content and Sleep Recording
struct SleepTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Sleep"), selection: $selectedSegment) {
                Text(String(localized: "Wind Down")).tag(0)
                Text(String(localized: "Sleep Rec")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if selectedSegment == 0 {
                WindDownView()
            } else {
                SleepRecordingView()
            }
        }
    }
}

#Preview {
    SleepTabView()
        .environment(SleepContentPlayerService())
        .environment(StoryProgressService())
        .environment(PremiumManager(paywallService: PaywallService()))
        .environment(PaywallService())
        .environment(AnalyticsService())
        .environment(AppearanceService())
        .environment(SleepRecordingService())
        .environment(AudioEngine())
        .environment(OnboardingService())
        .environment(SubscriptionService())
        .preferredColorScheme(.dark)
}
