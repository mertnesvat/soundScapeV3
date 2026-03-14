import SwiftUI

/// A full-width featured card with gradient background for highlighting premium content
struct LargeFeaturedCard: View {
    let content: SleepContent
    let progress: Double
    let isLocked: Bool
    let onTap: () -> Void
    let onLockedTap: () -> Void

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
                // Background - cover image or gradient
                if let coverName = content.coverImageName {
                    Image(coverName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    // Fallback gradient
                    backgroundGradient
                }

                // Content overlay
                contentOverlay
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                comingSoonOverlay
            )
            .premiumLocked(isLocked: isLocked, onTap: onLockedTap)
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

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            // Duration and play button
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(content.formattedDuration)
                        .font(.subheadline)
                }

                Spacer()

                if content.isAvailable {
                    playButton
                }
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
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
                audioFileName: "yoga_nidra_1.mp3",
                coverImageName: nil
            ),
            progress: 0.0,
            isLocked: false,
            onTap: {},
            onLockedTap: {}
        )

        LargeFeaturedCard(
            content: SleepContent(
                id: "featured-2",
                title: "The Moonlit Forest",
                narrator: "James Cooper",
                duration: 2400,
                contentType: .sleepStory,
                description: "Journey through an enchanted forest under the silver moonlight.",
                audioFileName: "story_1.mp3",
                coverImageName: nil
            ),
            progress: 0.35,
            isLocked: true,
            onTap: {},
            onLockedTap: {}
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
            audioFileName: nil,
            coverImageName: nil
        ),
        progress: 0.0,
        isLocked: false,
        onTap: {},
        onLockedTap: {}
    )
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}
