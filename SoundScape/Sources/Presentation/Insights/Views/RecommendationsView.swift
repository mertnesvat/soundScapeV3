import SwiftUI

struct RecommendationsView: View {
    let recommendations: [SoundRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Recommendations")
                    .font(.headline)
            }

            if recommendations.isEmpty {
                Text("Use the app more to get personalized recommendations")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationCardView(recommendation: recommendation)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct RecommendationCardView: View {
    let recommendation: SoundRecommendation

    private var confidenceLabel: String {
        if recommendation.confidence >= 0.8 { return "High confidence" }
        if recommendation.confidence >= 0.5 { return "Medium confidence" }
        return "Based on general patterns"
    }

    private var confidenceColor: Color {
        if recommendation.confidence >= 0.8 { return .green }
        if recommendation.confidence >= 0.5 { return .yellow }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "waveform")
                    .font(.body)
                    .foregroundStyle(.purple)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.soundName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)

                    Text(confidenceLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Play button
            Button(action: {
                // Action handled by parent
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RecommendationsView(recommendations: [
        SoundRecommendation(
            soundId: "brown_noise",
            soundName: "Brown Noise",
            reason: "Associated with 85% quality sleep",
            confidence: 0.9
        ),
        SoundRecommendation(
            soundId: "rain_storm",
            soundName: "Rain Storm",
            reason: "Natural sounds mask distractions",
            confidence: 0.6
        ),
        SoundRecommendation(
            soundId: "pink_noise",
            soundName: "Pink Noise",
            reason: "Balanced frequencies aid deep sleep",
            confidence: 0.4
        )
    ])
    .padding()
    .preferredColorScheme(.dark)
}
