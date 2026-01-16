import SwiftUI

struct FeaturedStoryBanner: View {
    let story: Story
    let progressFraction: Double

    private var gradientColors: [Color] {
        switch story.category {
        case .fiction:
            return [.indigo.opacity(0.8), .purple.opacity(0.9)]
        case .nature:
            return [.green.opacity(0.8), .teal.opacity(0.9)]
        case .meditation:
            return [.purple.opacity(0.8), .pink.opacity(0.9)]
        case .asmr:
            return [.cyan.opacity(0.8), .blue.opacity(0.9)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Background gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)

                // Decorative icon
                HStack {
                    Spacer()
                    Image(systemName: story.category.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    // Featured badge
                    Text("FEATURED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        )

                    Spacer()

                    // Title
                    Text(story.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Narrator and duration
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text(story.narrator)
                                .font(.subheadline)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(story.formattedDuration)
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))

                    // Progress bar (if started)
                    if progressFraction > 0 {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: geometry.size.width * progressFraction, height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 4)
                    }
                }
                .padding(20)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 20) {
        FeaturedStoryBanner(
            story: LocalStoryDataSource.stories[0],
            progressFraction: 0.0
        )

        FeaturedStoryBanner(
            story: LocalStoryDataSource.stories[3],
            progressFraction: 0.35
        )
    }
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
