import SwiftUI

/// Combined Explore tab containing Discover community mixes and Adaptive sessions
struct ExploreTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Explore"), selection: $selectedSegment) {
                Text(String(localized: "Discover")).tag(0)
                Text(String(localized: "Adaptive")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if selectedSegment == 0 {
                DiscoverView()
            } else {
                AdaptiveView()
            }
        }
    }
}

#Preview {
    ExploreTabView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(PaywallService())
        .environment(PremiumManager(paywallService: PaywallService()))
        .environment(OnboardingService())
        .environment(SubscriptionService())
        .environment(AnalyticsService())
        .environment(AdaptiveSessionService(audioEngine: AudioEngine()))
        .preferredColorScheme(.dark)
}
