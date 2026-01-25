import SwiftUI

/// A standard horizontal card (140pt width) for displaying sleep content in section scrolling
struct SleepContentCardView: View {
    let content: SleepContent
    let progress: Double
    let onTap: () -> Void

    @Environment(AppearanceService.self) private var appearanceService
    @State private var isPressed = false

    private var categoryColor: Color {
        content.contentType.color
    }

    private var gradientColors: [Color] {
        [categoryColor.opacity(0.8), categoryColor.opacity(0.4)]
    }

    private var cardBackgroundColor: Color {
        if appearanceService.isOLEDModeEnabled {
            return Color(.systemGray6).opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover with gradient and icon
                coverImage

                // Title - fixed height for 2 lines
                Text(content.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40, alignment: .top)

                // Narrator
                Text(content.narrator)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(content.formattedDuration)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                // Progress bar - always reserve space for consistent height
                progressBar
                    .opacity(progress > 0 ? 1 : 0)
            }
            .frame(width: 140, height: 220)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                comingSoonOverlay
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Cover Image

    private var coverImage: some View {
        ZStack {
            if let coverName = content.coverImageName {
                // Use actual cover image
                Image(coverName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 116, height: 116)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Fallback to gradient with icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: content.contentType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)

                Capsule()
                    .fill(categoryColor)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Coming Soon Overlay

    @ViewBuilder
    private var comingSoonOverlay: some View {
        if !content.isAvailable {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.6))

                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Coming Soon")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
}

// MARK: - Scale Button Style

/// Custom button style that provides a subtle scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Available Content") {
    HStack(spacing: 16) {
        SleepContentCardView(
            content: SleepContent(
                id: "preview-1",
                title: "Deep Rest Yoga Nidra",
                narrator: "Sarah Williams",
                duration: 1200,
                contentType: .yogaNidra,
                description: "A deeply relaxing practice",
                audioFileName: "yoga_nidra_1.mp3",
                coverImageName: nil
            ),
            progress: 0.0,
            onTap: {}
        )

        SleepContentCardView(
            content: SleepContent(
                id: "preview-2",
                title: "The Dream Garden",
                narrator: "James Cooper",
                duration: 1800,
                contentType: .sleepStory,
                description: "A peaceful journey",
                audioFileName: "story_1.mp3",
                coverImageName: nil
            ),
            progress: 0.45,
            onTap: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}

#Preview("Coming Soon") {
    SleepContentCardView(
        content: SleepContent(
            id: "preview-3",
            title: "Peaceful Dreams",
            narrator: "Emma Stone",
            duration: 900,
            contentType: .sleepHypnosis,
            description: "Coming soon",
            audioFileName: nil,
            coverImageName: nil
        ),
        progress: 0.0,
        onTap: {}
    )
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}
