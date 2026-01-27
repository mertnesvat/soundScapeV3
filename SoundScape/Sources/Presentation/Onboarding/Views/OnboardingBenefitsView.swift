import SwiftUI

struct OnboardingBenefitsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    private let benefits: [(icon: String, title: String, description: String)] = [
        ("waveform.path", "Scientifically-designed sounds", "Crafted to promote relaxation and sleep"),
        ("person.crop.circle", "Personalized for you", "Recommendations based on your needs"),
        ("moon.stars.fill", "Fall asleep faster", "Most users report improvement in days"),
        ("chart.line.uptrend.xyaxis", "Track your progress", "See how your sleep improves over time")
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
            Text("Your journey to\nbetter sleep")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 32)
                .padding(.bottom, 32)

            // Benefit cards
            VStack(spacing: 16) {
                ForEach(benefits, id: \.title) { benefit in
                    BenefitCard(
                        icon: benefit.icon,
                        title: benefit.title,
                        description: benefit.description
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingBenefitsView(
        onContinue: {},
        onBack: {}
    )
}
