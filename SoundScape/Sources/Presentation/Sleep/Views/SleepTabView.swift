import SwiftUI

struct SleepTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Section"), selection: $selectedSegment) {
                Text(String(localized: "Wind Down")).tag(0)
                Text(String(localized: "Sleep Rec")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if selectedSegment == 0 {
                WindDownView()
            } else {
                SleepRecordingView()
            }
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    SleepTabView()
        .environment(StoryProgressService())
        .environment(SleepContentPlayerService())
        .environment(AppearanceService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(SleepRecordingService())
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
