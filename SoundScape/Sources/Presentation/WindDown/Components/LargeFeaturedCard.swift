import SwiftUI

/// A full-width featured card with gradient background for highlighting premium content
struct LargeFeaturedCard: View {
    let content: SleepContent
    let progress: Double
    let onTap: () -> Void

    @Environment(AppearanceService.self) private var appearanceService

    private var categoryColor: Color {
        content.contentType.color
    }

    private var gradientColors: [Color] {
        [categoryColor.opacity(0.8), categoryColor.opacity(0.5)]
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background gradient
                backgroundGradient

                // Decorative icon
                decorativeIcon

                // Content overlay
                contentOverlay
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                comingSoonOverlay
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 16)
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    // MARK: - Decorative Icon

    private var decorativeIcon: some View {
        HStack {
            Spacer()
            Image(systemName: content.contentType.icon)
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.2))
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Featured badge
            featuredBadge

            Spacer()

            // Title
            Text(content.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)

            // Description
            if !content.description.isEmpty {
                Text(content.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            // Narrator and duration
            HStack(spacing: 16) {
                // Narrator
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text(content.narrator)
                        .font(.subheadline)
                }

                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(content.formattedDuration)
                        .font(.subheadline)
                }

                Spacer()

                // Play button
                if content.isAvailable {
                    playButton
                }
            }
            .foregroundColor(.white.opacity(0.9))

            // Progress bar (if started)
            if progress > 0 {
                progressBar
            }
        }
        .padding(20)
    }

    // MARK: - Featured Badge

    private var featuredBadge: some View {
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
    }

    // MARK: - Play Button

    private var playButton: some View {
        Image(systemName: progress > 0 ? "play.circle.fill" : "play.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding(8)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.25))
            )
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
        .padding(.top, 4)
    }

    // MARK: - Coming Soon Overlay

    @ViewBuilder
    private var comingSoonOverlay: some View {
        if !content.isAvailable {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))

                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    Text("We're working on this content")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Featured Available") {
    VStack(spacing: 20) {
        LargeFeaturedCard(
            content: SleepContent(
                id: "featured-1",
                title: "Deep Rest Yoga Nidra",
                narrator: "Sarah Williams",
                duration: 1800,
                contentType: .yogaNidra,
                description: "A deeply relaxing 30-minute practice to help you unwind and prepare for restful sleep.",
                audioFileName: "yoga_nidra_1.mp3"
            ),
            progress: 0.0,
            onTap: {}
        )

        LargeFeaturedCard(
            content: SleepContent(
                id: "featured-2",
                title: "The Moonlit Forest",
                narrator: "James Cooper",
                duration: 2400,
                contentType: .sleepStory,
                description: "Journey through an enchanted forest under the silver moonlight.",
                audioFileName: "story_1.mp3"
            ),
            progress: 0.35,
            onTap: {}
        )
    }
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}

#Preview("Featured Coming Soon") {
    LargeFeaturedCard(
        content: SleepContent(
            id: "featured-3",
            title: "Peaceful Dreams Hypnosis",
            narrator: "Dr. Emma Stone",
            duration: 1500,
            contentType: .sleepHypnosis,
            description: "Gentle hypnotherapy to guide you into deep, restful sleep.",
            audioFileName: nil
        ),
        progress: 0.0,
        onTap: {}
    )
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}
