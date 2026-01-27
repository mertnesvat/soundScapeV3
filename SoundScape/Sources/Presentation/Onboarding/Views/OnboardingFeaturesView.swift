import SwiftUI

struct OnboardingFeaturesView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    private let features: [(icon: String, title: String, description: String)] = [
        ("waveform.path", "27+ Premium Sounds", "Nature, rain, white noise, and relaxing music"),
        ("slider.horizontal.3", "Custom Sound Mixing", "Blend multiple sounds to create your perfect mix"),
        ("timer", "Smart Sleep Timer", "Gentle fade-out as you drift off to sleep"),
        ("brain.head.profile", "Binaural Beats", "Brainwave entrainment for deep relaxation"),
        ("chart.bar.fill", "Sleep Insights", "Track your patterns and see improvement")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Headline
            Text("Everything you need\nfor better sleep")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 32)
                .padding(.bottom, 32)

            // Feature list
            VStack(spacing: 20) {
                ForEach(Array(features.enumerated()), id: \.element.title) { index, feature in
                    FeatureRow(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(title: "See Your Plan", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var delay: Double = 0
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Checkmark (animated)
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4).delay(delay + 0.3)) {
                appeared = true
            }
        }
    }
}

#Preview {
    OnboardingFeaturesView(
        onContinue: {},
        onBack: {}
    )
}
