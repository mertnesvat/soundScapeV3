import SwiftUI

struct AdaptiveView: View {
    @Environment(AdaptiveSessionService.self) private var adaptiveService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager

    var body: some View {
        NavigationStack {
            Group {
                if premiumManager.isPremiumRequired(for: .adaptiveMode) {
                    // Premium preview for free users
                    AdaptivePremiumPreview(
                        onUnlock: {
                            paywallService.triggerPaywall(placement: "adaptive_mode") {}
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if adaptiveService.isActive {
                                ActiveAdaptiveSessionView()
                            } else {
                                modeSelectionView
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Adaptive"))
            .background(Color(.systemBackground))
        }
    }

    private var modeSelectionView: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("Choose an Adaptive Mode"))
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AdaptiveMode.allCases) { mode in
                AdaptiveModeCardView(mode: mode) {
                    adaptiveService.start(mode: mode)
                }
            }
        }
    }
}

// MARK: - Premium Preview for Adaptive Mode

struct AdaptivePremiumPreview: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Feature illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text(LocalizedStringKey("Adaptive Soundscapes"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(LocalizedStringKey("Context-aware sound environments that adapt to your activities"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "moon.stars.fill", text: String(localized: "Sleep Mode - Calming sounds for bedtime"))
                featureRow(icon: "brain.head.profile", text: String(localized: "Focus Mode - Concentration-enhancing audio"))
                featureRow(icon: "leaf.fill", text: String(localized: "Relax Mode - Stress-relieving soundscapes"))
                featureRow(icon: "figure.mind.and.body", text: String(localized: "Meditate Mode - Deep mindfulness support"))
            }
            .padding(.horizontal, 24)

            Spacer()

            // Unlock button
            Button(action: onUnlock) {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text(LocalizedStringKey("Unlock Adaptive Mode"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 30)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview("Premium User") {
    let audioEngine = AudioEngine()
    let paywallService = PaywallService()
    return AdaptiveView()
        .environment(AdaptiveSessionService(audioEngine: audioEngine))
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}

#Preview("Free User Preview") {
    AdaptivePremiumPreview(onUnlock: {})
        .preferredColorScheme(.dark)
}
