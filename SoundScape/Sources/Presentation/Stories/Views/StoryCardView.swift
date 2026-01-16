import SwiftUI

struct StoryCardView: View {
    let story: Story
    let progressFraction: Double

    private var gradientColors: [Color] {
        switch story.category {
        case .fiction:
            return [.indigo, .purple]
        case .nature:
            return [.green, .teal]
        case .meditation:
            return [.purple, .pink]
        case .asmr:
            return [.cyan, .blue]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover placeholder with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: story.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Title
            Text(story.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Narrator
            Text(story.narrator)
                .font(.caption)
                .foregroundColor(.secondary)

            // Duration
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(story.formattedDuration)
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Progress bar (if started)
            if progressFraction > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(height: 4)

                        Capsule()
                            .fill(story.category.color)
                            .frame(width: geometry.size.width * progressFraction, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        StoryCardView(
            story: LocalStoryDataSource.stories[0],
            progressFraction: 0.0
        )

        StoryCardView(
            story: LocalStoryDataSource.stories[3],
            progressFraction: 0.45
        )
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
