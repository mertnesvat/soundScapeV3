import SwiftUI

struct ExploreTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Section"), selection: $selectedSegment) {
                Text(String(localized: "Discover")).tag(0)
                Text(String(localized: "Adaptive")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if selectedSegment == 0 {
                DiscoverView()
            } else {
                AdaptiveView()
            }
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    ExploreTabView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(AdaptiveSessionService(audioEngine: AudioEngine()))
        .preferredColorScheme(.dark)
}
